/*
 * This class manages Kinect and performs basics image and contour processing operations
 * to provide contour, hull, and stuff.
 */

class KBlob implements ControlListener {
  
  PApplet that;

  int depthMin, depthMax;
  int padL, padR, padT, padB;
  float polyApprox;

  // image processing
  int depthW, depthH, rgbW, rgbH;
  int[] depthMap;
  int[] depthMaskGray; // gray
  color[] depthMaskColor; //color
  PImage rgbImg, depthImg, depthMaskImg;
  OpenCV opencv;
  ArrayList <Contour> contours;
  Contour maxContour;
  Contour _hull;
  float maxArea;
  int filterSize;
  int blurKernel;

  ArrayList <Vec2D> hull;
  ArrayList <Vec2D> contour;
  Vec2D com;
  Rectangle bbox;
  float zoomF;
  PVector pos;

  KBlob (PApplet pa) {
    
    this.that = pa;
    this.polyApprox = 0.8;

    depthMin = 100;
    depthMax = 1800;
    padL = 50;
    padR = 600;
    padT = 0;
    padB = 479;
    filterSize = 7;
    blurKernel = 11;
    
    pos = new PVector(0,0);
    
    zoomF = 1.0;
    print("here");
  }

  void init() {
    depthW = context.depthWidth();
    depthH = context.depthHeight();
    rgbW = context.rgbWidth();
    rgbH =  context.rgbHeight();
    depthMaskGray = new int[depthW * depthH];
    depthMaskColor = new color[depthW * depthH];
    opencv = new OpenCV(that, depthW, depthH);
    depthMaskImg = createImage(depthW, depthH, RGB);
    hull = new ArrayList <Vec2D> ();
    contour = new ArrayList <Vec2D> ();
    contours = new ArrayList <Contour> ();

    initHud();
  }

  void update () {

    context.update();
    if ((context.nodes() & SimpleOpenNI.NODE_DEPTH) == 0 || (context.nodes() & SimpleOpenNI.NODE_IMAGE) == 0) {
      println("No frame.");
      return;
    }

    depthMap = context.depthMap();
    depthImg = context.depthImage();
    rgbImg = context.rgbImage();

    for (int x=0;x<depthW;x+=1) {
      for (int y=0;y<depthH;y+=1) {

        int idx = x + y * depthW;
        depthMaskGray[idx] = 0;
        depthMaskColor[idx] = #000000;
        float d = depthMap[idx];

        if (x > padL && x < padR && y > padT && y < padB && d > depthMin && d < depthMax) {
          depthMaskGray[idx] = 255;
          depthMaskColor[idx]= #FFFFFF;
        }
      }
    }

    depthMaskImg.pixels = depthMaskColor;
    depthMaskImg.loadPixels();
    opencv.loadImage(depthMaskImg);
    opencv.useGray();
    opencv.erode();
    opencv.dilate();
    opencv.blur(blurKernel);
    opencv.threshold(128);
    depthMaskImg = opencv.getOutput();

    contours = opencv.findContours();

    if (contours.size() <= 0) {
      return;
    }

    maxContour = contours.get(0);
    maxArea = 0;

    for (Contour contour : contours) {
      float area = contour.area();
      if (area > maxArea) {
        maxArea = area;
        maxContour = contour;
      }
    }

    bbox = maxContour.getBoundingBox(); 
    com = new Vec2D(bbox.x + bbox.width / 2, bbox.y + bbox.height/2);
    com.x = zoomF * com.x + pos.x;
    com.y = zoomF * com.y + pos.y; 

    _hull = maxContour.getConvexHull();
    _hull.setPolygonApproximationFactor(_hull.getPolygonApproximationFactor() * polyApprox);
    _hull = _hull.getPolygonApproximation();

    hull.clear();
    
    hull.add(new Vec2D(zoomF * bbox.x + pos.x, zoomF * bbox.y + pos.y));
    hull.add(new Vec2D(zoomF * (bbox.x + bbox.width) + pos.x, zoomF * bbox.y + pos.y));
    hull.add(new Vec2D(zoomF * (bbox.x + bbox.width) + pos.x, zoomF * (bbox.y + bbox.height) + pos.y));
    hull.add(new Vec2D(zoomF * bbox.x + pos.x, zoomF * (bbox.y + bbox.height) + pos.y));
    
    /*
    for (PVector p : _hull.getPoints()) {
      hull.add(new Vec2D(zoomF * p.x + pos.x, zoomF * p.y + pos.y));
    }
    */
  }



  /*
   * HUD related
   */

  void initHud() {
    hud.addDepthRangeListener(this);
    hud.setDepthDefault(this.depthMin, this.depthMax);
    hud.addPadRangeListener(this);
    hud.setPadDefault(this.padL, this.padR, this.padT, this.padB);
    hud.addSlidersListener(this);
    hud.setSlidersDefault(pos.x, pos.y, zoomF);
  }

  public void controlEvent(ControlEvent event) {
    if (event.isFrom("depth")) {
      depthMin = int(event.getController().getArrayValue(0));
      depthMax = int(event.getController().getArrayValue(1));
    } 
    else if (event.isFrom("hpad")) {
      padL = int(event.getController().getArrayValue(0));
      padR = int(event.getController().getArrayValue(1));
    } 
    else if (event.isFrom("vpad")) {
      padT = int(event.getController().getArrayValue(0));
      padB = int(event.getController().getArrayValue(1));
    }
    else if (event.isFrom("x")) {
      pos.x = int(event.getController().getValue());
    }
    else if (event.isFrom("y")) {
      pos.y = int(event.getController().getValue());
    }
    else if (event.isFrom("zoom")) {
      zoomF = event.getController().getValue();
    }
  }
}

