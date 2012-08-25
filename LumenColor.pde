/*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/

//------------------------------------------------------------------------------
//	Project:	LumenColor
//	File Name:	LumenColor.pde
//	Purpose:	Control of a RGB Lamp
//				Selectable mode of operation (fading color,constant color, (sound sensitive))
//				via bluetooth connection by an Android App
//  Author:		Malte Kraft, Johannes Lenz
//	Created:	19-07-2012
//	Updates:	
//		25-08-2012, Malte Kraft
//				Added setValue
//				Added PowerOff() and fading in and out	
//------------------------------------------------------------------------------

#include <FlexiTimer2.h>// Timing for rainbow effect
#include <MeetAndroid.h>// Bluetooth Android <-> Arduino
#include <avr/power.h>	// For sleep mode
#include <avr/sleep.h>

#define MIN_DELAY 0.1	// Minimum delay in ms for each color step to change
#define MAX_DELAY 500	// Maximum delay in ms for each color step to change

#define R_PORT 5		// ports for the colors on the Arduino board
#define G_PORT 10
#define B_PORT 6

// RGB Color Space
byte r_intens = 0;		// current intensity of the colors [0,255] <-> [0,100] % PWM
byte g_intens = 0;
byte b_intens = 0;

// HSV Color Space
float hue = 1;			// Hue  [0,360)
float saturation = 1;	// Saturation [0,1]
float value = 1;		// Value [0,1]

// Rainbow Mode settings
long t_delay = 30;		// delay [MIN_DELAY,MAX_DELAY] in ms
byte mode = 1;			// Mode of Operation: 0->Off,1->Rainbow Mode, 2->Fixed Color

// Bluetooth Connection
MeetAndroid bt;

// Declare Functions
void setColor( );
void setDelay( int tempo );
void RainbowColor();
void HSVtoRGB( float hue, float saturation, float value, byte &r, byte &g, byte &b);
void startRainbow();
void powerOff();
void setMode( byte flag, byte numOfValues );
void newColor( byte flag, byte numOfValues );
void setSpeed( byte flag, byte numOfValues );
void setValue( byte flag, byte numOfValues );

/*
* void setup()
* Purpose:
*	Executed on Arduino startup, set Ports etc.
* Created:
*	19-07-2012, Malte Kraft
*/
void setup()
{
	Serial.begin(38400);

	// Register Callback functions for BT
	bt.registerFunction( setMode , 'm' );
	bt.registerFunction( newColor , 'c' );
	bt.registerFunction( setSpeed , 's' );
	bt.registerFunction( setValue , 'v' );

	// Output Ports
	pinMode( R_PORT, OUTPUT );
	pinMode( G_PORT, OUTPUT );
	pinMode( B_PORT, OUTPUT );
	pinMode( 13, OUTPUT );	// LED on PIN13 showing Arduino is awake

	digitalWrite( 13, HIGH );

	FlexiTimer2::set(t_delay, RainbowColor);
	startRainbow();			// Default Mode of the Lamp: Rainbow Mode

}

void loop()
{
	// Receive BT Data
	bt.receive();
}

/*
* void setMode( byte mode, byte numOfValues )
* Purpose: 
*	Changes the mode of the lamp after a BT Command, Callback function for flag 'm' 
* Parameter:
*	See Amarino Doc
* Created:
*	09-08-2012, Malte Kraft
*/
void setMode( byte flag, byte numOfValues ){
	int nmode = bt.getInt();

	if( nmode == 0 ){
		powerOff();
	}else if( nmode == 2 ){
		// Constant Color
		if( mode == 1 ){
			FlexiTimer2::stop();
		}
		mode = 2;
	}else if( nmode == 1 ){
		// Rainbow Color Mode
		startRainbow();
	}
}

/*
* void newColor( byte flag, byte numOfValues )
* Purpose:
*	Changes the color to color received by BT communication
* Parameter:
*	See Amarino Doc
* Created:
*	09-08-2012, Malte Kraft
*/

void newColor( byte flag, byte numOfValues ){
	if( numOfValues == 3 ){
		int data[numOfValues];
		bt.getIntValues(data);
		HSVtoRGB( data[0] , data[1], data[2], r_intens,g_intens,b_intens );
		setColor();
	}
}

/*
* void setSpeed( byte flag, byte numOfValues )
* Purpose:
*  Changes the color to color received by BT communication
* Parameter:
*	See Amarino Doc
* Created:
*	09-08-2012, Malte Kraft
*/
void setSpeed( byte flag, byte numOfValues ){
	if( mode == 1 ){
		// If Rainbow Mode is activated
		setDelay( bt.getInt() );
	}
}

/* 
* void setValue( byte flag, byte numOfValues )
* Purpose:
*	Sets the value after  Bluetooth data received
* Parameter:
*	See Amarino Doc
* Created:
	25-08-2012, Malte Kraft
*/
void setValue( byte flag, byte numOfValues ){
	float nvalue = bt.getFloat(); // Get the new Value [0,255]
	nvalue = constrain( nvalue/255.0, 0.0,1.0 );

	value = nvalue; 
    HSVtoRGB( hue, saturation, value , r_intens,g_intens,b_intens );
	setColor();
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
	setColor( );
}

/*
* void startRainbow()
* Purpose:
*	Start the Rainbow Mode
* Created:
*	02-08-2012, Malte Kraft
*/
void startRainbow(){
	mode = 1;
	FlexiTimer2::start();
}
/*
* void setColor( )
* Purpose:
*	Set the color of the lamp by setting the intensity of the RGB components stored in  r_intens,g_intens,b_intens
* Created:	
*	19-07-2012, Malte Kraft
* Changes:
*	02-08-2012, Malte Kraft
*		- No Parameters anymore
*		- uses values in vars r_intens,g_intens,b_intens to set as output
*/
void setColor( ){
	analogWrite( R_PORT , r_intens );
	analogWrite( G_PORT , g_intens );
	analogWrite( B_PORT , b_intens );
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
void setDelay( int tempo ){
	t_delay = map( tempo , 255,0, MIN_DELAY, MAX_DELAY );
	FlexiTimer2::set(t_delay, RainbowColor);
	FlexiTimer2::start();
}

/*
* void powerOff()
* Purpose: 
*	Puts the Arduino in sleep Mode, turns the lights off
* Created:
*	02-08-2012, Malte Kraft
* Updated:
*	25-08-2012, Malte Kraft	
*		- Added fading in and out
*/
void powerOff(){
	digitalWrite( 13, LOW );

	if( mode == 1 ){
		FlexiTimer2::stop();
	}

	mode = 0;

	
	// Dim the lamp
	float cvalue = value;

	for( int i=100; i>=0; i-- ){
		HSVtoRGB( hue , saturation , cvalue/100*i , r_intens, g_intens, b_intens );
		setColor();
		delay( 10 );
	}

	set_sleep_mode(SLEEP_MODE_IDLE); 
	power_adc_disable();
	power_spi_disable();
	power_timer0_disable();
	power_timer1_disable();
	power_timer2_disable();
	power_twi_disable();

	sleep_mode();		// Arduino going to sleep
	sleep_disable();	// After waking up
	power_all_enable();

	// Undim the lamp
	for( int i=0; i<=100; i++ ){
		HSVtoRGB( hue , saturation , cvalue/100*i , r_intens, g_intens, b_intens );
		setColor();
		delay(10);
	}

	digitalWrite( 13, HIGH );
}