
module main;

import std.math;
import std.md5;
import std.random;
import std.stdio;

import dsfml.system.all;
import dsfml.window.all;
import dsfml.graphics.all;

enum int Nx = 10; // # Neuronen pro Zeile
enum int Ny = cast(int) (sqrt(3)/2*Nx + 0.5); // rounded, should be 9 for Nx=10
enum N = Nx*Ny; //! # neurons

enum tau = 0.8f; //! time constant
enum I = 0.3f; //! intensity
enum T = 0.05f; //! threshold
enum sigma = 0.24f; //! Einheit: meter

enum float sqr32 = sqrt(3)/2;

__gshared float[N] A = void; //! firing A

struct Vec2(T)
{
	T x,y;
	
	Vec2 opSub(Vec2 v)
	{
		return Vec2(x-v.x, y-v.y);
	}
}
alias Vec2!float Vec2f;
alias Vec2!int Vec2i;

void main()
{
	RenderWindow window = new RenderWindow(VideoMode(1024, 768), "CANN", Style.Default, ContextSettings(24,8,0,3,1));
	
	foreach(ref e; A)
		e = uniform(0.f, sqrt(N));

	visualize();

	float[N] Aneu = void;

	enum gain = 2; // element of [1,3]
	enum bias = 0; // element of  [0, pi/3]
	enum vmax = 0.0275f; // meter / Zeitschritt
	enum vx = 0.02;
	enum vy = 0;
	static assert(sqrt(vx^^2 + vy^^2) <= vmax);
	
	while (window.isOpened())
	{
		Event evt;

		while (window.getEvent(evt))
		{
			switch(evt.Type)
			{
				case EventType.Closed:
					window.close();
			}
		}
		
		if (input.is)
		// one time step
		float sumA = 0;
		foreach(e; A)
			sumA += e;
	
		for(int i=0; i<N; i++)
		{
			auto veci = idx2vec(i);
			int ix = i % Nx; // Spaltennummer
			int iy = i / Nx; // Zeilennummer

			
			// Berechne B
			float tmp = 0;
			for(int j=0; j<N; j++)
			{
				auto vecj = idx2vec(j);
				int jx = j % Nx;
				int jy = j / Nx;

				float d = distTriSqr( (jx - ix) / cast(float)Nx  + gain * (cos(bias)*vx -sin(bias) + vy), sqr32 * (jy - iy) / cast(float) Ny  + gain * (sin(bias)*vx + cos(bias)*vy));
				tmp += A[j] * ( I * exp( -(d)/(sigma^^2) ) - T );
			}
			
			// Berechne A
			Aneu[i] = (1-tau)*tmp + tau*(tmp/(sumA));
			if (Aneu[i] < 0)
				Aneu[i] = 0;
		}
		
		A = Aneu; // copy
	}
	writeln("done");
	visualize();
}

Vec2i idx2vec(int i)
{
	return Vec2i(i % Nx, i / Nx); // Spalten- und Zeilennummer resp.
}

float distTriSqr(float dx, float dy)
{
//	writefln("distTriSqr(%f, %f)", dx, dy);
	float res = dx^^2 + dy^^2, tmp;
	
	if ((tmp = (dx - 0.5f)^^2 + (dy + sqr32)^^2 ) < res)
		res = tmp;

	if ((tmp = (dx - 0.5f)^^2 + (dy - sqr32)^^2 ) < res)
		res = tmp;

	if ((tmp = (dx + 0.5f)^^2 + (dy + sqr32)^^2 ) < res)
		res = tmp;

	if ((tmp = (dx + 0.5f)^^2 + (dy - sqr32)^^2 ) < res)
		res = tmp;

	if ((tmp = (dx - 1.f)^^2 + dy^^2 ) < res)
		res = tmp;

	if ((tmp = (dx + 1.f)^^2 + dy^^2 ) < res)
		res = tmp;
	
	return res;
}

void visualize()
{
	foreach(y; 0..Ny)
		writeln(A[y*Nx .. (y+1) * Nx]);
}

unittest
{
//	pragma(msg, distTriSqr(0.5f/10f - 1.5f/10f, 0.5f/9f - 1.5f/9f));
}