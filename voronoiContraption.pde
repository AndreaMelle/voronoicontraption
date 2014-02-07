import org.opencv.core.*;
import org.opencv.imgproc.*;
import gab.opencv.*;
import toxi.math.conversion.*;
import toxi.geom.*;
import toxi.math.*;
import toxi.geom.mesh2d.*;
import toxi.util.datatypes.*;
import toxi.util.events.*;
import toxi.geom.mesh.subdiv.*;
import toxi.geom.mesh.*;
import toxi.math.waves.*;
import toxi.util.*;
import toxi.math.noise.*;
import java.util.List;
import java.awt.Rectangle;
import SimpleOpenNI.*;
import controlP5.*;
import toxi.physics2d.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.constraints.*;

SimpleOpenNI  context;
boolean live;
String recordPath;

List <Vec2D> vPoints;
List <Vec2D> aPoints;
Voronoi voronoi;
HUD hud;

int xmin, xmax, ymin, ymax;
float debugScale = 1.0;
boolean pause;

KBlob blob;

void setup() {
  size(1400, 450, P2D);

  live = false;
  recordPath = "rec_02.oni";

  xmin = 0;
  xmax = width;
  ymin = 0;
  ymax = height;
  pause = false;

  smooth(8);

  vPoints = new ArrayList <Vec2D> ();
  aPoints = new ArrayList <Vec2D> ();
  voronoi = new Voronoi();
  hud = new HUD(this);
  blob = new KBlob(this);

  initKinect();

  blob.init();

  hud.load();
}

void addDeafult() {

  vPoints.add(blob.com);
  Vec2D p, p0, p1;
  int l = blob.hull.size();
  float f = 0;

  for (int i = 1; i < l; i++) {
    p0 = new Vec2D(blob.hull.get(i-1));
    p1 = new Vec2D(blob.hull.get(i));
    f = 1.0 - min(1.0, floor(abs(p0.y - height) / 5.0) * floor(abs(p1.y - height) / 5.0));
    p = mirror(blob.com, p0.add(new Vec2D(0, f * 40)), p1.add(new Vec2D(0, f * 40)));
    vPoints.add(p);
  }

  p0 = new Vec2D(blob.hull.get(l-1));
  p1 = new Vec2D(blob.hull.get(0));
  f = 1.0 - min(1.0, floor(abs(p0.y - height) / 5.0) * floor(abs(p1.y - height) / 5.0));
  p = mirror(blob.com, p0.add(new Vec2D(0, f * 40)), p1.add(new Vec2D(0, f * 40)));
  vPoints.add(p);

  for (Vec2D q : aPoints) {
    vPoints.add(q);
  }
}

void draw() {

  if (!pause) {
    blob.update();
  }

  pushMatrix();

  background(255);

  scale(debugScale);

  noFill();
  stroke(180, 40, 40);
  strokeWeight(5);

  strokeWeight(1);
  stroke(180, 180, 180);
  rect(0, 0, width, height);

  for (int i = 0; i < polygons.size(); i++) {
    Polygon2D poly = polygons.get(i);

    for (int j = 1; j < poly.vertices.size(); j++) {
      line(poly.vertices.get(j - 1), poly.vertices.get(j));
    }

    line(poly.vertices.get(poly.vertices.size() - 1), poly.vertices.get(0));
  } 

  strokeWeight(2);
  stroke(5, 166, 238);

  for (int i = 0; i < polygons.size(); i++) {
    Polygon2D poly = polygons.get(i);

    if (poly.vertices.size() <= 3) {
      continue;
    }

    Vec2D mid = midpoint(poly.vertices.get(0), poly.vertices.get(1));
    beginShape();
    vertex(mid.x, mid.y);

    for (int j = 2; j < poly.vertices.size(); j++) {
      bezierVertex(poly.vertices.get(j-1), poly.vertices.get(j-1), midpoint(poly.vertices.get(j-1), poly.vertices.get(j)));
    }

    bezierVertex(poly.vertices.get(poly.vertices.size() - 1), poly.vertices.get(poly.vertices.size() - 1), midpoint(poly.vertices.get(poly.vertices.size() - 1), poly.vertices.get(0)));
    bezierVertex(poly.vertices.get(0), poly.vertices.get(0), midpoint(poly.vertices.get(0), poly.vertices.get(1)));
    endShape();
  }

  if (hud.drawHull()) {
    strokeWeight(1);
    stroke(0, 255, 0);

    for (int i = 1; i < blob.hull.size(); i++) {
      line(blob.hull.get(i-1), blob.hull.get(i));
    }
    line(blob.hull.get(blob.hull.size() - 1), blob.hull.get(0));
  }

  popMatrix();

  hud.display();
}

void mousePressed() {
  Vec2D p = new Vec2D(mouseX/debugScale, mouseY/debugScale);
  aPoints.add(p);
}

void keyPressed() {
  if (key == 'p') { 
    pause = !pause;
  }

  if (key == 'c') {
    aPoints.clear();
  }

  if (key == '1') {
    hud.save();
  }

  if (key == '2') {
    hud.load();
  }
}

void initKinect() {
  if (live) {
    context = new SimpleOpenNI(this);
    if (context.isInit() == false)
    {
      println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
      exit();
      return;
    }
  } 
  else {
    context = new SimpleOpenNI(this, recordPath);
  }

  context.enableDepth();
  context.enableRGB();
  context.setMirror(true);
  context.alternativeViewPointDepthToImage();
}

