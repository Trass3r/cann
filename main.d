
module main;

import std.math;
import std.md5;
import std.datetime;
import std.random;
import std.stdio;
import std.string;

import dsfml.system.all;
import dsfml.window.all;
import dsfml.graphics.all;

import derelict.opengl.gl;
import derelict.opengl.glu;

import colormaps;

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

void reshape (int w, int h)
{
	glViewport(0, 0, cast(GLsizei)w, cast(GLsizei)h);

	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	gluPerspective (60, cast(GLfloat)w / cast(GLfloat)h, 1.0, 1000.0);

	glMatrixMode (GL_MODELVIEW);
}

//__gshared float xpos = 851.078f, ypos = 351.594f, zpos = 281.033f, xrot = 758f, yrot = 238f, angle=0.0f, cScale=1.0f;
__gshared float xpos = 8.052496f, ypos = 3.747924f, zpos = -3.023191f, xrot = 753f, yrot = 932f, angle=0.0f, cScale=0.02f;
__gshared int lastx = 0, lasty = 0;

void camera ()
{
//	int posX = (int)xpos;
//	int posZ = (int)zpos;

	glRotatef(xrot,1.0,0.0,0.0);
	glRotatef(yrot,0.0,1.0,0.0);

	glTranslated(-xpos,-ypos,-zpos);

}

static void mouseMovement(int x, int y)
{

	int diffx=x-lastx; 
	int diffy=y-lasty; 
	lastx=x;

	lasty=y; 
	xrot += cast(float) diffy; 
	yrot += cast(float) diffx;

}

void main()
{
	bool updateValues = true;
	float max = 0;
	
	RenderWindow window = new RenderWindow(VideoMode(1024, 768), "CANN", Style.Default, ContextSettings(24,8,0,2,0));
	
	DerelictGL.load();
	DerelictGLU.load();

	reshape(window.width, window.height);
	window.active = true;

	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	
	Text fps = new Text(""c);
	fps.move(50.f, 50.f);
	fps.color = Color.WHITE;

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

	// Create a clock for measuring the time elapsed
	auto fpsClock = new StopWatch(AutoStart.yes);
	uint iFps;

	while (window.isOpened())
	{
		Event evt;

		while (window.getEvent(evt))
		{
			switch(evt.Type)
			{
				case EventType.Closed:
					window.close();
					break;
				case EventType.Resized:
					reshape(window.width, window.height);
					break;
				case EventType.KeyPressed:
					if (evt.Key.Code == KeyCode.U)
						updateValues = !updateValues;
					else if (evt.Key.Code == KeyCode.I)
						writefln("%f %f %f %f %f", xpos, ypos, zpos, xrot, yrot);
				default:
			}
		}
		
		float yrotrad = (yrot / 180 * 3.141592654f);
		float xrotrad = (xrot / 180 * 3.141592654f);
		
		if (window.input.isKeyDown(KeyCode.W))
		{
			xpos += sin(yrotrad) * cScale;
			zpos -= cos(yrotrad) * cScale;
			ypos -= sin(xrotrad) * cScale;
		}
		
		if (window.input.isKeyDown(KeyCode.S))
		{
			xpos -= sin(yrotrad) * cScale;
			zpos += cos(yrotrad) * cScale;
			ypos += sin(xrotrad) * cScale;
		}

		if (window.input.isKeyDown(KeyCode.D))
		{
			xpos += cos(yrotrad) * cScale;
			zpos += sin(yrotrad) * cScale;
		}

		if (window.input.isKeyDown(KeyCode.A))
		{
			xpos -= cos(yrotrad) * cScale;
			zpos -= sin(yrotrad) * cScale;
		}

		mouseMovement(window.input.mouseX, window.input.mouseY);

		if (updateValues)
		{
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
			
			max = 0;
			foreach(e; A)
				if (e > max)
					max = e;
		}
		
		glClearColor(0.0, 0.0, 0.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		glLoadIdentity();
		camera();

		glBegin(GL_TRIANGLE_STRIP);
			for (int x=0; x<Nx-1; x++)
				for (int y=0; y<Ny-1; y++)
				{
					Color c = jet[cast(size_t) (A[y*Nx + x]/max * 1023)];
					glColor3f(c.r, c.g, c.b);
					glVertex3f(x,   A[y*Nx + x]/max, y);

					c = jet[cast(size_t) (A[(y+1)*Nx + x]/max * 1023)];
					glColor3f(c.r, c.g, c.b);
					glVertex3f(x,   A[(y+1)*Nx + x]/max, y+1);

					c = jet[cast(size_t) (A[y*Nx + x+1]/max * 1023)];
					glColor3f(c.r, c.g, c.b);
					glVertex3f(x+1, A[y*Nx + x+1]/max, y);

					c = jet[cast(size_t) (A[(y+1)*Nx + x+1]/max * 1023)];
					glColor3f(c.r, c.g, c.b);
					glVertex3f(x+1, A[(y+1)*Nx + x+1]/max, y+1);
				}
		glEnd();

		// show FPS
		if(fpsClock.peek().seconds >= 1)
		{
			fps.text = std.string.format("%d fps", iFps);
			iFps = 0;
			fpsClock.reset();
		}
		++iFps;
		window.saveGLStates();
		window.draw(fps);
		window.restoreGLStates();

		window.display();
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