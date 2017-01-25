import processing.serial.*;
import cc.arduino.*;
Arduino arduino;  // main device

// poke variables
int touchSensorReading = 0;
static final int pokeTouchPin = 2;
static final int pokeViberatorPin = 3;

// badMoodAlert variables
static final int badMoodAnalogPin = 4;
static final int badMoodServoMotorPin = 11;
int miniServoOutput = 0;
float gsrThreshold = 0;
int gsrSensorInput = 0;
int servoMotorResumingTime = -1;
ServoMotorStatus servoMotorStatus = ServoMotorStatus.IDLE;

// twist variables
static final int twistAnalogPin = 1;
static final int twistServoMotorPin = 10;
int servo995Output = 0;
int twistInput = 0;
int previousTwistInput = 0;
int twistThreshold = 8;


void setup(){
  println("starting up the system...\n==========");
  
  // poke module initialization
  println("initializing poke function... ");
  arduino = new Arduino(this, Arduino.list()[5], 57600);
  arduino.pinMode(pokeTouchPin, Arduino.INPUT);
  arduino.pinMode(pokeViberatorPin, Arduino.OUTPUT);
  println("poke function initialization done\n==========");
  
  // badMoodAlert
  println("initializing bad mood detection... ");
  long sum = 0;
  arduino.pinMode(badMoodAnalogPin, Arduino.INPUT); //declare gsr into pin
  arduino.pinMode(badMoodServoMotorPin, Arduino.SERVO); //D11 control mini servo
  miniServoOutput = 0;
  arduino.servoWrite(badMoodServoMotorPin, miniServoOutput);//setup ring in relax mode
  delay(1000);  // wait for the miniServo to reset
  for(int i=0;i<1000;i++){
    gsrSensorInput=arduino.analogRead(badMoodAnalogPin);
    sum += gsrSensorInput;
    delay(5);
  }
  gsrThreshold = sum/1000;
  print("gsrThreshold = ");
  println(gsrThreshold);
  println("bad moon detection initialization done\n==========");

  // twist
  println("initializing twist detection... ");
  arduino.pinMode(twistAnalogPin, Arduino.INPUT); //declare potentiometer input pin
  arduino.pinMode(twistServoMotorPin, Arduino.SERVO); //D10 control servo 995
  servo995Output = 95; // adjusted value for servo 995 
  arduino.servoWrite(twistServoMotorPin, servo995Output);//setup ring upper mark pointing middle
  println("bad moon detection initialization done\n==========");

  println("initialization done\n==========\nstarting...");
}


void draw(){
  // poke logic
  arduino.digitalRead(2);
  touchSensorReading = arduino.digitalRead(2);
  if (touchSensorReading > 0){
    println("touched, touchSensor reading : " + touchSensorReading);
    arduino.digitalWrite(3, Arduino.HIGH);
  }
  else{
    arduino.digitalWrite(3, Arduino.LOW);
  }
  
  // badMoodAlert logic
  switch (servoMotorStatus){
    case IDLE:  
      gsrSensorInput = arduino.analogRead(badMoodAnalogPin);
      println("GSR threshold : " + gsrThreshold + "GSR Sensor Value = " + gsrSensorInput );
      miniServoOutput = (int)abs(gsrThreshold - gsrSensorInput);  
      if(miniServoOutput > 50){  // if current value differes from threshold by 50 check again to reduce noise
        gsrSensorInput = arduino.analogRead(badMoodAnalogPin);
        miniServoOutput = (int)abs(gsrThreshold - gsrSensorInput);
        if(miniServoOutput > 50){ // if it's still larger than 50
          servoMotorStatus = ServoMotorStatus.OPERATING;
          servoMotorResumingTime = (second() + 3) % 60; // 3 seconds for motor to rotate 
          arduino.servoWrite(badMoodServoMotorPin, miniServoOutput);
          println("bad mood detected");
        }
      }
      break;
    case OPERATING: // OPERATING
      println("operating");
      if(second() == servoMotorResumingTime){
        arduino.servoWrite(badMoodServoMotorPin, 0); // reset the motor position
        servoMotorResumingTime = (second() + 1) % 60; // 1 second to reset            
        servoMotorStatus = ServoMotorStatus.RESETTING;
      }
      break;
    case RESETTING: // RESETTING
      println("resetting");
      if(second() == servoMotorResumingTime){
        servoMotorStatus = ServoMotorStatus.IDLE;
      }
    break;
  }
 
  // twist logic
  twistInput = arduino.analogRead(twistAnalogPin);
  if(abs(twistInput - previousTwistInput) > twistThreshold){ 
    if(twistInput <= 505){
      if(twistInput > 145){
        servo995Output = (int)((twistInput - 145)/4.235);
      }
      else{
        servo995Output = 10;
      }  
    }
    else{
      if(twistInput < 853){
        servo995Output = (int)((twistInput - 505)/4.5 + 95);
      }
      else {
        servo995Output = 172;
      }
    }
    println(servo995Output);
    arduino.servoWrite(twistServoMotorPin, servo995Output);
  }
  previousTwistInput = twistInput;

  
  
}