# coding: utf-8

require 'bundler'
require 'json'
Bundler.require


module StringExtension
  refine String do
    def plural?
      /^.+s$/ === self
    end
    def singular?
      !plural?
    end
    def singularize
      self.sub /s$/, ''
    end
    def camelize
      self.split('_').map(&:capitalize).join(' ')
    end
  end
end

using StringExtension

class Library
  @@data = nil
  def self.data
    @@data ||= Plist::parse_xml('./example.plist')
  end
  def self.rows_of name, conditions = {}
    self.data[name].select{|row|
      conditions.all? {|property, value|
        property = property.to_s.camelize
        row[property].to_s.include? value
      }
    }
  end
  def self.track_field_values(field)
    self.tracks.map{|id,track| track[field] }.uniq.reject(&:nil?)
  end
  def self.search_tracks_by(filed, value)
    self.tracks.select{|id,track|
      self.track_fields.any? {|field| track[field].to_s.include? value }
    }
  end
  def self.method_missing(name, *args)
    name.to_s.tap do |name|
      if name.plural? && self.data.keys.include?(name.camelize)
        break self.send(:rows_of, name.camelize, args.first.tap{|_| break {} unless _ })
      elsif name.plural? && self.track_fields.include?(name.camelize.singularize)
        break self.send(:track_field_values, name.camelize.singularize)
      elsif name.singular? && name.start_with?('search_tracks_by_')
        break self.send(:search_tracks_by, name.sub('search_tracks_by_', '').camelize, args.first)
      else
        break super
      end
    end
  end
  def self.track_fields
    ['Name','Artist','Album Artist','Composer','Album','Genre','Kind']
  end
  def self.search_tracks(word)
    self.tracks.select{|id,track|
      self.track_fields.any? {|field| track[field].to_s.include? word }
    }
  end
end

Pry.prompt = [
   proc{">>> "},
   proc{">>* "},
]

pry
