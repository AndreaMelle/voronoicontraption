class HUD {

  ControlP5 cp5;
  //PMatrix3D currCameraMatrix;
  //PGraphics3D g3;

  controlP5.Range rangeDepth;
  controlP5.Range rangeHPad;
  controlP5.Range rangeVPad;
  Slider sliderX;
  Slider sliderY;
  Slider sliderZoom;
  
  Toggle drawHullToggle;

  Accordion accordion;

  HUD(PApplet pa) {
    //g3 = (PGraphics3D)g;

    cp5 = new ControlP5(pa);

    color text = color(1, 51, 77);
    int alpha = 220;

    Group depthGroup = cp5.addGroup("depth map").setBackgroundColor(color(255, alpha)).setBackgroundHeight(0);
    Group posGroup = cp5.addGroup("user pos").setBackgroundColor(color(255, alpha)).setBackgroundHeight(130);  

    rangeDepth = cp5.addRange("depth").setBroadcast(false) 
      .setPosition(10, 10).setSize(200, 20).setHandleSize(10).setColorCaptionLabel(text)
        .setRange(0, 5000).setRangeValues(0, 5000)
          .setBroadcast(true).moveTo(depthGroup);

    rangeHPad = cp5.addRange("hpad").setBroadcast(false) 
      .setPosition(10, 40).setSize(200, 20).setHandleSize(10).setColorCaptionLabel(text)
        .setRange(0, 639).setRangeValues(0, 639)
          .setBroadcast(true).moveTo(depthGroup);

    rangeVPad = cp5.addRange("vpad").setBroadcast(false) 
      .setPosition(10, 70).setSize(200, 20).setHandleSize(10).setColorCaptionLabel(text)
        .setRange(0, 479).setRangeValues(0, 479)
          .setBroadcast(true).moveTo(depthGroup);

    sliderX = cp5.addSlider("x").setBroadcast(false).setPosition(10, 10).setSize(200, 20).setColorCaptionLabel(text)
      .setRange(0, width).setValue(0).setBroadcast(true).moveTo(posGroup);

    sliderY = cp5.addSlider("y").setBroadcast(false).setPosition(10, 40).setSize(200, 20).setColorCaptionLabel(text)
      .setRange(0, height).setValue(0).setBroadcast(true).moveTo(posGroup);

    sliderZoom = cp5.addSlider("zoom").setBroadcast(false).setPosition(10, 70).setSize(200, 20).setColorCaptionLabel(text)
      .setRange(0.1f, 2.0f).setValue(0).setBroadcast(true).moveTo(posGroup);
      
    drawHullToggle = cp5.addToggle("draw hull").setBroadcast(false).setPosition(10, 100).setSize(20, 20).setColorCaptionLabel(text)
      .setValue(1).setBroadcast(true).moveTo(posGroup);

    accordion = cp5.addAccordion("acc").setPosition(10, 10).setWidth(250)
      .addItem(depthGroup).addItem(posGroup);

    accordion.close(0);
    accordion.close(1);
    accordion.setCollapseMode(Accordion.MULTI);
  }

  void display() {
    //currCameraMatrix = new PMatrix3D(g3.camera);
    //hint(DISABLE_DEPTH_TEST);
    //perspective();
    //camera();
    //resetShader();
    //noLights();

    //  Start HUD

    pushMatrix();
    PImage preview = blob.depthMaskImg;
    translate(width - preview.width * 0.25, height - preview.height * 0.25);
    scale(0.25);
    noStroke();
    image(preview, 0, 0, preview.width, preview.height);
    
    stroke(0, 255, 0);
    noFill();

    int padL = (int)rangeHPad.getArrayValue(0);
    int padR = (int)rangeHPad.getArrayValue(1);

    int padT = (int)rangeVPad.getArrayValue(0);
    int padB = (int)rangeVPad.getArrayValue(1);

    line(padL, 0, padL, preview.height);
    line(padR, 0, padR, preview.height);

    line(0, padT, preview.width, padT);
    line(0, padB, preview.width, padB);

    rect(0, 0, preview.width, preview.height);
    
    noStroke();
    popMatrix();
    
    /*
    pushMatrix();
    translate(0,height - 30,0);
    fill(0);
    palette.display(0.4f);
    popMatrix();
    */
    
    cp5.draw();
    //  End HUD
    //hint(ENABLE_DEPTH_TEST);
    //g3.camera = currCameraMatrix;
  }

  void addDepthRangeListener(ControlListener l) {
    rangeDepth.addListener(l);
  }

  void addPadRangeListener(ControlListener l) {
    rangeHPad.addListener(l);
    rangeVPad.addListener(l);
  }

  void setDepthDefault(float depthMin, float depthMax) {
    float[] values = new float[2];
    values[0] = depthMin;
    values[1] = depthMax;
    rangeDepth.setArrayValue(values);
  }

  void setPadDefault(float padL, float padR, float padT, float padB) {
    float[] values = new float[2];
    values[0] = padL;
    values[1] = padR;
    rangeHPad.setArrayValue(values);
    values[0] = padT;
    values[1] = padB;
    rangeVPad.setArrayValue(values);
  }

  void addSlidersListener(ControlListener l) {
    sliderX.addListener(l);
    sliderY.addListener(l);
    sliderZoom.addListener(l);
  }

  void setSlidersDefault(float x, float y, float zoom) {
    sliderX.setValue(x);
    sliderY.setValue(y);
    sliderZoom.setValue(zoom);
  }
  
  boolean drawHull() {
    int val = (int)(drawHullToggle.getValue());
    if (val == 1) {
      return true;
    } 
    else {
      return false;
    }
  }

  void save() {
    cp5.saveProperties(("hud.properties"));
  } 

  void load() {
    cp5.loadProperties(("hud.properties"));
  }

}
