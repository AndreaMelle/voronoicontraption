
/*
 * Manages Voronoi triangulation and all the particles used as voronoi points
 * Also, manages physcis of such particles
 */

class VoroManager {

  VerletPhysics2D physics;
  toxi.geom.Rect world;
  ArrayList <VDynamicParticle> dynamics;
  ArrayList <VStaticParticle> statics;
  float dynForceRad;
  float statForceRad;
  Voronoi voronoi;
  ArrayList <Polygon2D> polygons;
  List <Polygon2D> regions;
  boolean start;

  VoroManager () {

    dynForceRad = 100;
    statForceRad = 100;

    dynamics = new ArrayList <VDynamicParticle>();
    statics = new ArrayList <VStaticParticle> ();
    polygons = new ArrayList <Polygon2D> ();

    world = new toxi.geom.Rect(0, 0, width, height);
    physics = new VerletPhysics2D();
    physics.setDrag(0.05f);
    physics.setWorldBounds(world);
    start = false;
  }

  void init() {

    if (start) {
      return;
    }

    if (blob.com == null || blob.hull.size() == 0) {
      println("Cannot initialized VoroManager with no blob points.");
      return;
    }

    start = true;

    this.addStaticPoint(new Vec2D(0,0));
    
    for (int i = 1; i < blob.hull.size(); i++) {
      this.addStaticPoint(new Vec2D(0,0));
    }
    this.addStaticPoint(new Vec2D(0,0));
    
    // additional statics
    this.addStaticPoint(new Vec2D(0,0));
    this.addStaticPoint(new Vec2D(width,0));
    this.addStaticPoint(new Vec2D(width,height));
    this.addStaticPoint(new Vec2D(0,height));
    
    updateAllStatics();
  }

  void updateAllStatics() {
    
    statics.get(0).update(blob.com);
    
    Vec2D p, p0, p1;
    int l = blob.hull.size();
    float f = 0;

    for (int i = 1; i < l; i++) {
      p0 = new Vec2D(blob.hull.get(i-1));
      p1 = new Vec2D(blob.hull.get(i));
      f = 1.0 - min(1.0, floor(abs(p0.y - height) / 5.0) * floor(abs(p1.y - height) / 5.0));
      p = mirror(blob.com, p0.add(new Vec2D(0, f * 40)), p1.add(new Vec2D(0, f * 40)));
      statics.get(i).update(p);
    }

    p0 = new Vec2D(blob.hull.get(l-1));
    p1 = new Vec2D(blob.hull.get(0));
    f = 1.0 - min(1.0, floor(abs(p0.y - height) / 5.0) * floor(abs(p1.y - height) / 5.0));
    p = mirror(blob.com, p0.add(new Vec2D(0, f * 40)), p1.add(new Vec2D(0, f * 40)));
    
    statics.get(l).update(p);
  }

  void update() {

    if (!start) {
      try {
        this.init();
      } 
      catch (Exception e) {
      }
      return;
    }

    physics.update();

    for (VDynamicParticle p : dynamics) {
      p.update();
    }

    updateAllStatics();

    doVoronoi();
  }

  void doVoronoi() {
    voronoi = new Voronoi();

    // TODO merge points if they are too close

    for (VStaticParticle p : statics) {
      voronoi.addPoint(p.pos);
    }

    for (VDynamicParticle p : dynamics) {
      voronoi.addPoint(p.pos);
    }

    polygons.clear();
    regions = voronoi.getRegions();

    for (int i = 0; i < regions.size(); i++) {
      Polygon2D poly = regions.get(i);

      if (poly.vertices.size() <= 0) {
        continue;
      }

      Polygon2D polyClipped = new Polygon2D();

      for (int j = 1; j < poly.vertices.size(); j++) {
        Vec2D p0 = new Vec2D(poly.vertices.get(j - 1));
        Vec2D p1 = new Vec2D(poly.vertices.get(j));
        csClamp(p0, p1);
        polyClipped.add(p0);
        polyClipped.add(p1);
      }

      Vec2D p0 = new Vec2D(poly.vertices.get(poly.vertices.size() - 1));
      Vec2D p1 = new Vec2D(poly.vertices.get(0));
      csClamp(p0, p1);
      polyClipped.add(p0);
      polyClipped.add(p1);
      polygons.add(polyClipped);
    }
  }

  void addStaticPoint(Vec2D pos) {
    if (!start) {
      println("Cannot add points before init");
      return;
    }

    VStaticParticle p = new VStaticParticle(pos, this.statForceRad);
    for (VDynamicParticle d : dynamics) {
      d.addStatic(p);
    }
    statics.add(p);
  }

  void addDynamicPoint(Vec2D pos) {

    if (!start) {
      println("Cannot add points before init");
      return;
    }

    VDynamicParticle p = new VDynamicParticle(this.physics, pos, this.dynForceRad, this.statics);
    this.dynamics.add(p);
  }

  ArrayList <Vec2D> getAllPoints() {
    ArrayList <Vec2D> points = new ArrayList <Vec2D> ();

    for (VStaticParticle p : statics) {
      points.add(p.pos);
    }

    for (VDynamicParticle p : dynamics) {
      points.add(p.pos);
    }

    return points;
  }
}

abstract class VParticle {
  Vec2D pos;
}

class VStaticParticle extends VParticle {
  CircularConstraint cc;
  float radius;

  VStaticParticle(Vec2D pos, float radius) {
    this.pos = pos;
    this.radius = radius;
    cc = new CircularConstraint(this.pos, this.radius);
  }

  void update(Vec2D pos) {
    this.pos = pos;
    cc.circle.x = pos.x;
    cc.circle.y = pos.y;
  }
}

class VDynamicParticle extends VParticle {
  Vec2D pos;
  float radius;
  AttractionBehavior ab;
  VerletParticle2D vp;

  VDynamicParticle(VerletPhysics2D physics, Vec2D pos, float radius, ArrayList <VStaticParticle> statics) {
    this.pos = pos;
    this.radius = radius;
    vp = new VerletParticle2D(this.pos.x, this.pos.y);
    ab = new AttractionBehavior(vp, radius, -1.2f, 0.01f);

    for (VStaticParticle s : statics) {
      vp.addConstraint(s.cc);
    }

    physics.addParticle(vp);
    physics.addBehavior(ab);
  }

  void update() {
    this.pos.x = vp.x;
    this.pos.y = vp.y;
  }

  void addStatic(VStaticParticle s) {
    vp.addConstraint(s.cc);
  }

  void removeStatic(VStaticParticle s) {
    vp.addConstraint(s.cc);
  }

  void removeAllStatics() {
    vp.removeAllConstraints();
  }
}

