int CS_INSIDE = 0; //0000
int CS_LEFT = 1; //0001
int CS_RIGHT = 2; //0010
int CS_BOTTOM = 4; //0100
int CS_TOP = 8; //1000

Vec2D mirror(Vec2D p, Vec2D p0, Vec2D p1) {
  double dx, dy, a, b;
  long x2, y2;
  Vec2D p_out; //reflected point to be returned 

  dx  = (double) (p1.x - p0.x);
  dy  = (double) (p1.y - p0.y);

  a   = (dx * dx - dy * dy) / (dx * dx + dy*dy);
  b   = 2 * dx * dy / (dx*dx + dy*dy);

  x2  = Math.round(a * (p.x - p0.x) + b*(p.y - p0.y) + p0.x); 
  y2  = Math.round(b * (p.x - p0.x) - a*(p.y - p0.y) + p0.y);

  p_out = new Vec2D((int)x2, (int)y2); 

  return p_out;
}

class Line2D {
  Vec2D p0;
  Vec2D p1;

  Line2D(Vec2D p0, Vec2D p1, boolean clamp) {
    this.p0 = p0;
    this.p1 = p1;
    if (clamp) {
      this.clamp();
    }
  }

  boolean clamp() {
    return csClamp(this.p0, this.p1);
  }

  void draw() {
    line(p0, p1);
  }
}

Vec2D clamp(Vec2D p) {
  p.x = min(max(0, p.x), width);
  p.y = min(max(0, p.y), height);
  return p;
}

PVector midpoint(PVector p0, PVector p1) {
  return new PVector( (p0.x + p1.x)  / 2, (p0.y + p1.y) / 2, (p0.z + p1.z) / 2);
}

Vec2D midpoint(Vec2D p0, Vec2D p1) {
  return new Vec2D( (p0.x + p1.x)  / 2, (p0.y + p1.y) / 2);
}

void bezierVertex(PVector c0, PVector c1, PVector p) {
  bezierVertex(c0.x, c0.y, c1.x, c1.y, p.x, p.y);
}

void bezierVertex(Vec2D c0, Vec2D c1, Vec2D p) {
  bezierVertex(c0.x, c0.y, c1.x, c1.y, p.x, p.y);
}

void vertex(PVector p) {
  vertex(p.x, p.y, p.z);
}

void vertex(Vec2D p) {
  vertex(p.x, p.y);
}

void point(PVector p) {
  point(p.x, p.y, p.z);
}

void point(Vec2D p) {
  point(p.x, p.y);
}

void line(PVector p0, PVector p1) {
  line(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z);
}

void line(Vec2D p0, Vec2D p1) {
  line(p0.x, p0.y, p1.x, p1.y);
}

int csComputeCode(Vec2D p) {
  int code = CS_INSIDE;
  if (p.x < xmin) {
    code = code | CS_LEFT;
  }
  else if (p.x > xmax) {
    code = code | CS_RIGHT;
  }
  if (p.y < ymin) {
    code = code | CS_BOTTOM;
  }
  else if (p.y > ymax) {
    code = code | CS_TOP;
  }
  return code;
}

boolean csClamp(Vec2D p0, Vec2D p1) {
  // compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
  int outcode0 = csComputeCode(p0);
  int outcode1 = csComputeCode(p1);

  boolean accept = false;

  while (true) {
    if (0 == (outcode0 | outcode1)) { // Bitwise OR is 0. Trivially accept and get out of loop
      accept = true;
      break;
    } 
    else if ((outcode0 & outcode1) > 0) { // Bitwise AND is not 0. Trivially reject and get out of loop
      break;
    } 
    else {
      // failed both tests, so calculate the line segment to clip
      // from an outside point to an intersection with clip edge
      float x = 0;
      float y = 0;

      // At least one endpoint is outside the clip rectangle; pick it.
      int outcodeOut = outcode1;
      if (outcode0 > 0) {
        outcodeOut = outcode0;
      }

      // Now find the intersection point;
      // use formulas y = y0 + slope * (x - x0), x = x0 + (1 / slope) * (y - y0)
      if ( (outcodeOut & CS_TOP) > 0) {           // point is above the clip rectangle
        x = p0.x + (p1.x - p0.x) * (ymax - p0.y) / (p1.y - p0.y);
        y = ymax;
      } 
      else if ((outcodeOut & CS_BOTTOM) > 0) { // point is below the clip rectangle
        x = p0.x + (p1.x - p0.x) * (ymin - p0.y) / (p1.y - p0.y);
        y = ymin;
      } 
      else if ((outcodeOut & CS_RIGHT) > 0) {  // point is to the right of clip rectangle
        y = p0.y + (p1.y - p0.y) * (xmax - p0.x) / (p1.x - p0.x);
        x = xmax;
      } 
      else if ((outcodeOut & CS_LEFT) > 0) {   // point is to the left of clip rectangle
        y = p0.y + (p1.y - p0.y) * (xmin - p0.x) / (p1.x - p0.x);
        x = xmin;
      }

      // Now we move outside point to intersection point to clip
      // and get ready for next pass.
      if (outcodeOut == outcode0) {
        p0.x = x;
        p0.y = y;
        outcode0 = csComputeCode(p0);
      } 
      else {
        p1.x = x;
        p1.y = y;
        outcode1 = csComputeCode(p1);
      }
    }
  }

  return accept;
}
