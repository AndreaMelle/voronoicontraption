
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
  ArrayList <Polygon2D> regions;


  VoroManager () {

    dynamics = new ArrayList <VDynamicParticle>();
    statics = new ArrayList <VStaticParticle> ();
    polygons = new ArrayList <Polygon2D> ();
    regions = new ArrayList <Polygon2D> ();

    world = new toxi.geom.Rect(0, 0, width, height);
    physics = new VerletPhysics2D();
    physics.setDrag(0.05f);
    physics.setWorldBounds(world);
  }

  void init() {
    // init static particles from the hull
    // if no hull -> exception
  }

  void update() {
    physics.update();

    for (VDynamicParticle p : dynamics) {
      p.update();
    }

    for (int i = 0; i  < blob.hull.size(i); i++) {
      Vec2D pos = blob.hull.get(i);
      statics.get(i).update(pos);
    }

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

  void addStaticPoint() {
    VStaticParticle p = new VStaticParticle(Vec2D pos, float radius);
    for (VDynamicParticle d : dynamics) {
      d.addStatic(p);
    }
    statics.add(p);
  }

  void addDynamicPoint(Vec2D pos) {
    VDynamicParticle p = new VDynamicParticle(this.physics, pos, this.dynForceRad, this.statics);
    this.dynamics.add(p);
  }
}

abstract class VParticle {
  Vec2D pos;
}

class VStaticParticle extends VParticle {
  CircularConstraint cc;

  VStaticParticle(Vec2D pos, float radius) {
    this.pos = pos;
    cc = new CircularConstraint(this.pos, radius);
  }

  void update(Vec2D pos) {
    this.pos = pos;
    cc.circle.x = pos.x;
    cc.circle.y = pos.y;
  }
}

class VDynamicParticle extends VParticle {
  Vec2D pos;
  AttractionBehavior ab;
  VerletParticle2D vp;

  VDynamicParticle(VerletPhysics2D physics, Vec2D pos, float radius, ArrayList <VStaticParticle> statics) {
    this.pos = pos;
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

