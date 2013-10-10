# Credit: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/264573
module Sunrise
  class Location
    attr_accessor :latitude, :longitude, :offset

    def initialize(latitude, longitude)
      @latitude, @longitude = latitude, longitude
    end
  end

  class << self
    def sunrise(date, location, zenith = 90.8333)
      sun_rise_set :sunrise, date, location, zenith
    end

    def sunset(date, location, zenith = 90.8333)
      sun_rise_set :sunset, date, location, zenith
    end

  protected
    def to_rad(degrees)
      degrees * Math::PI/180
    end

    def to_deg(radians)
      radians * 180/Math::PI
    end

    def sun_rise_set(which, date, location, zenith)
      #step 1: first calculate the day of the year
      n = date.to_time.yday

      #step 2: convert the longitude to hour value and calculate an approximate time
      lng_hour = location.longitude/15
      t = n + ((6 - lng_hour) / 24) if which == :sunrise
      t = n + ((18 - lng_hour) / 24) if which == :sunset

      #step 3: calculate the sun's mean anomaly
      m = (0.9856 * t) - 3.289

      #step 4: calculate the sun's true longitude
      l = (m + (1.1916 * Math.sin(to_rad(m))) + (0.020 * Math.sin(to_rad(2 * m))) + 282.634) % 360

      #step 5a: calculate the sun's right ascension
      ra = to_deg(Math.atan(0.91764 * Math.tan(to_rad(l)))) % 360
      ###step 5b: right ascension value needs to be in the same quadrant as L
      lquadrant = (l/90).floor * 90
      raquadrant = (ra/90).floor * 90
      ra = ra + (lquadrant - raquadrant)

      #step 5c: right ascension value needs to be converted into hours
      ra /= 15

      #step 6: calculate the sun's declination
      sinDec = 0.39782 * Math.sin(to_rad(l))
      cosDec = Math.cos(Math.asin(sinDec))
      #step 7a: calculate the sun's local hour angle
      cosH = (Math.cos(to_rad(zenith)) - (sinDec * Math.sin(to_rad(location.latitude)))) / (cosDec * Math.cos(to_rad(location.latitude)))

      unless (-1..1).include?(cosH)
        return cosH > 1 ? :down_all_day : :up_all_day
      end

      #step 7b: finish calculating H and convert into hours
      h = (360 - to_deg(Math.acos(cosH))) / 15 if which == :sunrise
      h = (to_deg(Math.acos(cosH)))/15         if which == :sunset

      #step 8: calculate local mean time
      t = h + ra - (0.06571 * t) - 6.622
      t %= 24

      #step 9: convert to UTC
      time = date.to_time.beginning_of_day.advance(:days => (t - lng_hour)/24)
      time.advance(:seconds => time.utc_offset)
    end
  end
end
