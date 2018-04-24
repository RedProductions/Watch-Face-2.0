//code's intention
import android.content.Intent;
import android.content.IntentFilter;
//recieve broadcast
import android.content.BroadcastReceiver;
//code's context (current watch face)
import android.content.Context;
//battery access
import android.os.BatteryManager;
//vibrator access
import android.os.Vibrator;
//all sensors (only using step counter)
import android.hardware.Sensor;
import android.hardware.SensorManager;
//know events
import android.hardware.SensorEvent;
//be able to recieve said events
import android.hardware.SensorEventListener;
//network permissions and security
import android.os.StrictMode;

//current temperature
float temperature = 0;
//current conditions
String weather = " ";
//current condition code. See https://developer.yahoo.com/weather/archive.html#examples
int weatherCode;
//Day of the week
String day = " ";
//current colorCode according to weather
color weatherColor = color(255);

// Yahoo weather uses WOEID (Where On Earth IDentifier) 
// https://en.wikipedia.org/wiki/WOEID
String woeid = "3458";

//flag to check once in the chosen minute
boolean hasCheckedWeather;

//sensors for the step counter
SensorManager manager;
Sensor sensor;
SensorListener listener;

//vibrator object and flag to vibrate once every hour
Vibrator vibe;
boolean hasVibed;

//step count and its adjustment (android step counter counts once, offset is to substract current count to start at 0
//                               ex: step counter is at 1000, offset = count, step = count - offset, step = 0)
int offset = -1;
int steps;
//flag reset the step amount at midnight
boolean resetStep;

//what time to vibrate (what minute in the hour (0-59))
final int vibeTime = 0;

//what is the amount of steps to achieve each day
final int stepGoal = 5000;

//what time to update weather
final int weatherTime = 0;


void setup(){
  
  fullScreen();
  
  strokeWeight(5);
  
  textAlign(CENTER, CENTER);
  
  //low frame rate to improve battery life
  frameRate(1);
  
  colorMode(HSB);
  
  //hasn't checked the weather
  hasCheckedWeather = false;
  
  //hasn't vibrated yet
  hasVibed = false;
  
  //hasn't reset the step counter yet
  resetStep = false;
  
  //create context
  Context context = getContext();
  manager = (SensorManager)context.getSystemService(Context.SENSOR_SERVICE);
  sensor = manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER);  
  listener = new SensorListener();  
  manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_NORMAL);  
  
  //go get weather information
  getWeather();
  weatherColor = getWeatherColor();
  
}




void draw(){
  
  //get application's context to access battery level (context is face watch)
  Context context;
  IntentFilter ifilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
  Intent batteryStatus;
  context = getContext();
  
  //create vibrator from context
  vibe = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
  
  //access battery from context
  batteryStatus = context.registerReceiver(null, ifilter);
  
  //access battery level from battery
  int level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
  
  //dark grey background
  background(0, 0, 15);
  
  //ONLY SHOWN IF SCREEN IS NOT IN AMBIANT MODE
  if(!wearAmbient()){
    
    //OUTER RIM
    noFill();
    stroke(0, 252, 234);
    ellipse(width/2, height/2, width - 2, height - 2);
    
    //SECONDS ARC
    float col = (second() * 85 / 60);
    stroke(col, 255, 255);
    arc(width/2, height/2, width/3 * 2, height/3 * 2, -PI/2, - PI/2 + (second() * TWO_PI / 60));
    
    //BATTERY LEVEL ARC
    //green to red according to percentage
    col = (level * 85 / 100);
    stroke(col, 255, 255);
    arc(width/2, height/2, width/5 * 4, height/5 * 4, -PI, - PI + (level * PI / 100));
    
    //STEPS COUNTER ARC
    if(steps < stepGoal){
      //red to green arc according to amount of steps compared to goal
      col = (steps * 85 / stepGoal);
      stroke(col, 255, 255);
      arc(width/2, height/2, width/5 * 4, height/5 * 4, 0, (steps * PI / stepGoal));
    }else {
      //blue arc if goal is achieved
      col = 145;
      stroke(col, 255, 255);
      arc(width/2, height/2, width/5 * 4, height/5 * 4, 0, PI);
    }
    
    
    stroke(255);
    
    //Battery and Steps lines
    line(width/2 - (width/5 * 4)/2 - 2, height/2, width/2 - (width/5 * 4)/2 + 2, height/2);
    line(width/2 + (width/5 * 4)/2 - 2, height/2, width/2 + (width/5 * 4)/2 + 2, height/2);
    
    line(width/2, height/2 - (height/5 * 4)/2 - 2, width/2, height/2 - (height/5 * 4)/2 + 2);
    line(width/2, height/2 + (height/5 * 4)/2 - 2, width/2, height/2 + (height/5 * 4)/2 + 2);
    
    //Seconds lines
    line(width/2, height/2 - (width/3 * 2)/2 + 2, width/2, height/2 - (width/3 * 2)/2 -2);
    
    
    
    //WEATHER
    //text(weatherCode, width/2, height/2 - height/6 - height/10 - height/20);
    textSize(height/10);
    //weather color recieved by code
    stroke(weatherColor);
    fill(weatherColor);
    text(nf(temperature, 0, 0) + "°C", width/2, height/2 - height/6 - height/20);
    
    
    fill(255);
    
    //DAY
    text(day, width/2, height/2 + height/8 + height/20);
    
    noFill();
    
    //STEP AMOUNT
    textSize(height/15);
    if(steps >= 0){
      text(steps, width/2, height - height/15);
    }else {
      text("-/-", width/2, height - height/15);
    }
    
    //BATTERY LEVEL
    text(level + "%", width/2, height/20);
    
  }
  
  
  //TIME
  noStroke();
  fill(255);
  textSize(height/6);
  //set to the 12 hours mode
  int hour = hour();
  if(hour() > 12){
    hour = hour() - 12;
  }
  if(hour == 0){
    hour = 12;
  }
  text(nf(hour, 2, 0) + ":" + nf(minute(), 2, 0), width/2, height/2 - height/12);
  textSize(height/8);
  
  //get last 2 digits of year  
  float y = year();
  float yearDivTen = (y/100);
  float yearDivTenNF = yearDivTen - floor(yearDivTen);
  int year = int(yearDivTenNF * 100);
  //DATE
  text(nf(day(), 2, 0) + "/" + nf(month(), 2, 0) + "/" + nf(year, 2, 0), width/2, height/2 + height/16);
  
  //actions to do each hour at vibrate defined minute
  if(minute() == vibeTime && !hasVibed){
    //vibrate for 300 milliseconds
    vibe.vibrate(300);
    //set vibration flag to true (prevent continuous vibration for an entire minute)
    hasVibed = true;
    
  }else if(minute() != vibeTime){
    //reset availability to vibrate next hour
    hasVibed = false;
  }
  
  //action to do each hour at weather refresh minute
  if(minute() == weatherTime && !hasCheckedWeather){
    //grab weather
    getWeather();
    //set weather text color
    weatherColor = getWeatherColor();
    //set check flag to true (prevent continuous checking for the entire minute)
    hasCheckedWeather = true;
  }else if(minute() != weatherTime){
    //reset availability to check next hour
    hasCheckedWeather = false;
  }
  
  if(hour() == 1 && minute() == 0 && !resetStep){
    //reset step count each day
    steps = 0;
    offset = -1;
    
    //set reset flag to true (prevent continuous reseting of the step counter)
    resetStep = true;
    
  }else if(hour() != 1 && minute() != 0){
    //reset availability to reset next day
    resetStep = false;
  }
  
}

void getWeather(){
  
  //allow network security access
  StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
  StrictMode.setThreadPolicy(policy);

  try{
    
    // The URL for the XML document
    String url = "http://query.yahooapis.com/v1/public/yql?format=xml&q=select+*+from+weather.forecast+where+woeid=" + woeid + "+and+u='C'";
    
    // Load the XML document
    XML xml = loadXML(url);
  
    // Grab the weather condition element
    XML condition = xml.getChild("results/channel/item/yweather:condition");
    
    XML forecast = xml.getChild("results/channel/item/yweather:forecast");
    
    // Get the attributes we want:
      //temperature (int)
      temperature = condition.getInt("temp");
      //weather condition (string)
      weather = condition.getString("text");
      //weather code (int)
      weatherCode = condition.getInt("code");
      //day of the week
      day = forecast.getString("day");
    
    //Farenheith to Celsuis
    //temperature = (temperature - 32) * 0.555;
    //
    
  }catch(android.os.NetworkOnMainThreadException e){
    //catch if network cannot be reached
    
    //set weather to chaos if can't access api
    weatherCode = 0;
    temperature = 100;
    
  }
  
}

//EVENT HANDLER
public void resume() {
  if (manager != null) {
    manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_NORMAL);
  }
}

public void pause() {
  if (manager != null) {
    manager.unregisterListener(listener);
  }
}
//

//STEP COUNTER
class SensorListener implements SensorEventListener {
  public void onSensorChanged(SensorEvent event) {
    if (offset == -1) offset = (int)event.values[0]; 
    steps = (int)event.values[0] - offset;
  }
  public void onAccuracyChanged(Sensor sensor, int accuracy) { }
}


color getWeatherColor(){
  
  //set text color according to the weather (representative color)
  
  //default color to pure white in case of an error in the recieved code
  color col = color(255);
  
  if(weatherCode >= 0 && weatherCode <= 3){
    //catastrophic events (tornado, tropical storm, hurricane and heavy thunder)
    col = color(0, 255, 255);
  }else if(weatherCode == 4 || (weatherCode >= 37 && weatherCode <= 39) || weatherCode == 45 || weatherCode == 47){
    //thunder (not heavy thunder)
    col = color(40, 255, 0.8 * 255);
  }else if((weatherCode >= 5 && weatherCode <= 10) || weatherCode == 17 || weatherCode == 18 || weatherCode == 25 || weatherCode == 35){
    //freezing (not snow but can include some snow(hail, freezing rain, mix of ice and snow, etc.))
    col = color(formatHue(198), 0.4 * 255, 255);
  }else if(weatherCode == 11 || weatherCode == 12 || weatherCode == 40){
    //rain (only rain, from light rain to heavy rain, no thunder or freezing)
    col = color(formatHue(238), 0.9 * 255, 255);
  }else if((weatherCode >= 13 && weatherCode <= 16) ||  (weatherCode >= 41 && weatherCode <= 43) || weatherCode == 46){
    //snow (only snow, from light to storm)
    col = color(255);
  }else if((weatherCode >= 19 && weatherCode <= 30 && weatherCode != 25) || weatherCode == 44){
    //cloud or obstructed vision (no fall, smog, fog, dust, etc.)
    col = color(0, 0, 0.6 * 255);
  }else if(weatherCode == 31 || weatherCode == 33){
    //clear night (or small amout of clouds)
    col = color(formatHue(223), 255, 0.35 * 255);
  }else if(weatherCode == 32 || weatherCode == 34){
    //clear day (or small amout of clouds)
    col = color(formatHue(60), 255, 255);
  }else if(weatherCode == 36){
    //hot (no more info given)
    col = color(formatHue(43), 255, 255);
  }else if(weatherCode == 3200){
    //no info available
    col = color(formatHue(295), 255, 255);
  }
  
  return col;
  
}

//hue from (x/360) to (x/255)
int formatHue(int hue){
  return hue * 255 / 360;
}