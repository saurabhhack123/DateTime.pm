/* Copyright (c) 2003 Dave Rolsky
   All rights reserved.
   This program is free software; you can redistribute it and/or
   modify it under the same terms as Perl itself.  See the LICENSE
   file that comes with this distribution for more details. */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <math.h>

/* necessary on Win32 */
#ifdef _finite
#  define finite _finite
#endif

/* 2 ** 28 - 307 */
#define RANGE_CUTOFF        (268435456 - 307)
#define DAYS_PER_400_YEARS  146097
#define DAYS_PER_4_YEARS    1461
#define MARCH_1             306

#define SECONDS_PER_DAY     86400

const int PREVIOUS_MONTH_DOY[12] =  { 0,
                                      31,
                                      59,
                                      90,
                                      120,
                                      151,
                                      181,
                                      212,
                                      243,
                                      273,
                                      304,
                                      334 };

const int PREVIOUS_MONTH_DOLY[12] = { 0,
                                      31,
                                      60,
                                      91,
                                      121,
                                      152,
                                      182,
                                      213,
                                      244,
                                      274,
                                      305,
                                      335 };

IV
_real_is_leap_year(IV y)
{
  IV r = 0;

  /* We need to have this first so that year 0 is a leap year */
  if (y % 400 == 0) {
    r = 1;
  } else if (y % 100 == 0) {
    r = 0;
  } else if (y % 4 == 0) {
    r = 1;
  }

  return r;
}

MODULE = DateTime       PACKAGE = DateTime

PROTOTYPES: ENABLE

void
_rd2ymd(self, d, extra = 0)
     SV* self;
     IV d;
     IV extra;

     PREINIT:
        IV y, m;
        IV c;
        IV quarter;
        IV yadj = 0;
        IV dow, doy, doq;
        IV rd_days;

     PPCODE:
        rd_days = d;

        if (d > RANGE_CUTOFF) {
          yadj = (d - DAYS_PER_400_YEARS + MARCH_1 ) / DAYS_PER_400_YEARS + 1;
          d -= (yadj * DAYS_PER_400_YEARS) - MARCH_1;
        } else {
          d += MARCH_1;

          if (d <= 0) {
            yadj = -1 * (((-1 * d) / DAYS_PER_400_YEARS) + 1);
            d -= yadj * DAYS_PER_400_YEARS;
          }
        }

        /* c is century */
        c =  ((d * 4) - 1) / DAYS_PER_400_YEARS;
        d -= c * DAYS_PER_400_YEARS / 4;
        y =  ((d * 4) - 1) / DAYS_PER_4_YEARS;
        d -= y * DAYS_PER_4_YEARS / 4;
        m =  ((d * 12) + 1093) / 367;
        d -= ((m * 367) - 1094) / 12;
        y += (c * 100) + (yadj * 400);
        if (m > 12) {
          ++y;
          m -= 12;
        }

        EXTEND(SP, extra ? 7 : 3);
        PUSHs(sv_2mortal(newSViv(y)));
        PUSHs(sv_2mortal(newSViv(m)));
        PUSHs(sv_2mortal(newSViv(d)));

        if (extra) {
	  quarter = ( ( 1.0 / 3.1 ) * m ) + 1;
          dow = ((rd_days + 6) % 7) + 1;
          PUSHs(sv_2mortal(newSViv(dow)));

          if (_real_is_leap_year(y)) {
            doy = PREVIOUS_MONTH_DOLY[m - 1] + d;
	    doq = doy - PREVIOUS_MONTH_DOLY[ (3 * quarter) - 3 ];
          } else {
            doy = PREVIOUS_MONTH_DOY[m - 1] + d;
	    doq = doy-PREVIOUS_MONTH_DOY[ (3 * quarter ) - 3 ];
          }

          PUSHs(sv_2mortal(newSViv(doy)));
          PUSHs(sv_2mortal(newSViv(quarter)));
          PUSHs(sv_2mortal(newSViv(doq)));
        }

void
_ymd2rd(self, y, m, d)
     SV* self;
     IV y;
     IV m;
     IV d;

     PREINIT:
        IV adj;

     PPCODE:
        if (m <= 2) {
          adj = (14 - m) / 12;
          y -= adj;
          m += 12 * adj;
        } else if (m > 14) {
          adj = (m - 3) / 12;
          y += adj;
          m -= 12 * adj;
        }

        if (y < 0) {
          adj = (399 - y) / 400;
          d -= DAYS_PER_400_YEARS * adj;
          y += 400 * adj;
        }

        d += (m * 367 - 1094) /
             12 + y % 100 * DAYS_PER_4_YEARS /
             4 + (y / 100 * 36524 + y / 400) - MARCH_1;

        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(d)));

void
_seconds_as_components(self, secs, utc_secs = 0)
     SV* self;
     IV secs;
     IV utc_secs;

     PREINIT:
        IV h, m, s;

     PPCODE:
        h = secs / 3600;
        secs -= h * 3600;

        m = secs / 60;

        s = secs - (m * 60);

        if (utc_secs >= SECONDS_PER_DAY) {

          if (utc_secs >= SECONDS_PER_DAY + 1)
            croak("Invalid UTC RD seconds value: %d", utc_secs);

          s += (utc_secs - SECONDS_PER_DAY) + 60;
          m = 59;
          h--;

          if (h < 0)
            h = 23;
        }

        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(h)));
        PUSHs(sv_2mortal(newSViv(m)));
        PUSHs(sv_2mortal(newSViv(s)));

void
_normalize_seconds(self, days, secs)
     SV* self;
     SV* days;
     SV* secs;

     PPCODE:
        if (finite(SvNV(days)) && finite(SvNV(secs))) {
          IV d = SvIV(days);
          IV s = SvIV(secs);
          IV adj;

          if (s < 0) {
            adj = (s - 86399) / SECONDS_PER_DAY;
          } else {
            adj = s / SECONDS_PER_DAY;
          }

          d += adj;
          s -= adj * SECONDS_PER_DAY;

          sv_setiv(days, (IV) d);
          sv_setiv(secs, (IV) s);
        }

void
_time_as_seconds(self, h, m, s)
     SV* self;
     IV h;
     IV m;
     IV s;

     PPCODE:
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(h * 3600 + m * 60 + s)));

void
_is_leap_year(self, y)
     SV* self;
     IV y;

     PPCODE:
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(_real_is_leap_year(y))));
