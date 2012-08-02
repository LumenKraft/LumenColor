//------------------------------------------------------------------------------
//	Project:	LumenColor
//	File Name:	LumenColor.pde
//	Purpose:	Control of a RGB Lamp
//				Selectable mode of operation (fading color,constant color, (sound sensitive))
//				via bluetooth connection by an Android App
//  Author:		Malte Kraft, Johannes Lenz
//	Created:	19-07-2012
//------------------------------------------------------------------------------
#include <FlexiTimer2.h>

#define MIN_DELAY 0.1	// Minimum delay in ms for each color step to change
#define MAX_DELAY 500	// Maximum delay in ms for each color step to change

#define R_PORT 5		// ports for the colors on the Arduino board
#define G_PORT 10
#define B_PORT 6

// RGB Color Space
byte r_intens = 0;			// current intensity of the colors [0,255] <-> [0,100] % PWM
byte g_intens = 0;
byte b_intens = 0;

// HSV Color Space
float hue = 1;			// Hue  [0°,360°)
float saturation = 1;	// Saturation [0,1]
float value = 1;		// Value [0,1]

// Rainbow Mode settings
long t_delay = 30;		// delay [MIN_DELAY,MAX_DELAY] in ms
byte mode = 0;			// Mode of Operation: 0->Rainbow Mode, 1->Fixed Color

// Declare Functions
void setColor(byte r,byte g, byte b );
void setDelay( char tempo );
void RainbowColor();
void HSVtoRGB( float hue, float saturation, float value, byte &r, byte &g, byte &b);

/*
* void setup()
* Purpose:
*	Executed on Arduino startup, set Ports etc.
* Created:
*	19-07-2012, Malte Kraft
*/
void setup()
{
	// Output Ports
	pinMode( R_PORT, OUTPUT );
	pinMode( G_PORT, OUTPUT );
	pinMode( B_PORT, OUTPUT );
	FlexiTimer2::set(t_delay, RainbowColor);
	FlexiTimer2::start();

	Serial.begin(9600);
}

void loop()
{
	// Bluetooth abfragen	
	if (Serial.available() > 0) {
		int a =Serial.parseInt();
		setDelay( a );
	}
	if( mode == 0 ){
		// Rainbow Mode
		
	}
	
}


/*
* void RainbowColor()
* Purpose:
*	Changes the color for creating an rainbow effect
* Created:	
*	19-07-2012, Malte Kraft
*/
void RainbowColor(){
	hue = hue+0.25;			// Hue+0.25 -> Intensity of one RGB Color +- 1
	hue = (hue)>=360?0:hue; // Ring counter 
	HSVtoRGB( hue , saturation, value, r_intens,g_intens,b_intens );

	analogWrite( R_PORT , r_intens );
	analogWrite( G_PORT , g_intens );
	analogWrite( B_PORT , b_intens );
}

/*
* void setColor(byte r,byte g, byte b )
* Purpose:
*	Set the color of the lamp by setting the intensity of the RGB components
* Parameter:
*	r		Intensity [0,255] red
*	g		Intensity [0,255] green
*	b		Intensity [0,255] blue
* Created:	
*	19-07-2012, Malte Kraft
*/
void setColor(byte r,byte g, byte b ){
	r_intens = r;
	g_intens = g;
	b_intens = b;
}

/*
* void HSVtoRGB( float hue, float saturation, float value, byte &r, byte &g, byte &b)
* Purpose:
*	Convert from HSV Space to RGB Space
* Parameter
*	hue			Hue  [0°,360°)
*	saturation	Saturation [0,1]
*	value		Value [0,1]
*	r			Red component [0,255]
*	g			Green component [0,255]
*	b			Blue component [0,255]
* Created:	
*	19-07-2012, Malte Kraft
* Comment:
*	see http://de.wikipedia.org/wiki/HSV-Farbraum
*/
void HSVtoRGB( float hue, float saturation, float value, byte &r, byte &g, byte &b){
	if( saturation == 0 ){
		// Neutral Grey => R=G=B=V
		r = g = b = value;
		return;
	}

	byte hi;
	float h,p,q,t,f;
	
	h = hue/60;
	hi = floor( h );
	f = h-hi;
	p = value*(1-saturation);
	q = value*(1-saturation*f);
	t = value*(1-saturation*(1-f));

	switch( hi ){
		case 0:
			r = int(255*value);
			g = int(255*t);
			b = int(255*p);
			break;
		case 1:
			r = int(255*q);
			g = int(255*value);
			b = int(255*p);
			break;
		case 2:
			r = int(255*p);
			g = int(255*value);
			b = int(255*t);
			break;
		case 3:
			r = int(255*p);
			g = int(255*q);
			b = int(255*value);
			break;
		case 4:
			r = int(255*t);
			g = int(255*p);
			b = int(255*value);
			break;
		default:
			r = int(255*value);
			g = int(255*p);
			b = int(255*q);
			break;
	}
}

/*
* void setDelay( char tempo )
* Purpose:
*	set the delay for changing color in rainbow mode in [MIN_DELAY,MAX_DELAY] by a value tempo [0,255]
* Parameter:
*	tempo		Value for the delay [0,255] => 2^8 steps
* Created:	
*	19-07-2012, Malte Kraft
*/
void setDelay( char tempo ){
	t_delay = map( tempo , 0,255, MIN_DELAY, MAX_DELAY );
	FlexiTimer2::set(t_delay, RainbowColor);
	FlexiTimer2::start();
}