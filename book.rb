# coding: utf-8

# Add local extensions to Prophecy here.
# This file will be loaded by the CLI.

#require 'pry'
#require 'pry-debugger'

require 'csv'

module Prophecy
  class CLI < Thor

    desc "markdown_verseindex", "Add page IDs to versepages.md and generate verse index for TOC"
    def markdown_verseindex

      versepath = File.join('manuscript', 'markdown', 'versepages.md')

      text = IO.read(versepath)

      # Add page IDs
      if text.include?('{:.dhp-verse}')
        text.gsub!('{:.dhp-verse}', '{:.dhp-verse #pageN}')
        n = 1
        while text =~ /#pageN/
          text.sub!('#pageN', "#page#{n}")
          n += 1
        end

        # Backup versepages.md
        FileUtils.cp(versepath, "#{versepath}.bak")

        File.open(versepath, "w"){|f| f << text }
      end

      pages = text.scan(/[{]:.dhp-verse (#page[0-9]+)[}]/)
      versenum = text.scan(/> \*(s\. [0-9-]+)\*$/)
      firstlines = text.scan(/\n\n> ([ùàÈè\w…\.;\?\!'‘’, –-]+)[\.;\?\!'‘’, \\–-]*$/m)

      #binding.pry

      unless pages.size == versenum.size && versenum.size == firstlines.size
        puts "pages: #{pages.size} versenum: #{versenum.size} firstlines: #{firstlines.size}"
        puts "Something wrong with the matches, the numbers are not equal."
        exit 2
      end

      # Write index as csv
      CSV.open('verseindex.csv', 'w') do |csv|
        pages.each_with_index do |page, index|
          csv << [ page[0], "#{versenum[index][0]} - #{firstlines[index][0]}" ]
        end
      end

    end

  end

  class Book

    def render_navpoints
      ret = ""
      lastplay = nil
      @navpoints.each_with_index do |nav, idx|
        ret += "<navPoint id=\"nav#{nav['playOrder']}\" playOrder=\"#{nav['playOrder']}\">\n"
        ret += "<navLabel><text>#{nav['text']}</text></navLabel>\n"
        ret += "<content src=\"#{nav['src']}\"/>"

        next_nav = @navpoints[idx+1]
        if !next_nav.nil? && next_nav['level'] < nav['level']
          d = nav['level'] - next_nav['level'] + 1
          d.times{ ret += "</navPoint>\n" }
        elsif next_nav.nil? || next_nav['level'] == nav['level']
          ret += "</navPoint>\n"
        end
        lastplay = nav['playOrder']
      end

      # Add verse index navpoints

      require 'csv'

      playorder = lastplay + 1

      ret += "<navPoint id=\"nav#{playorder}\" playOrder=\"#{playorder}\">\n"
      ret += "<navLabel><text>Index of Verses</text></navLabel>\n"
      ret += "<content src=\"Text/versepages.xhtml#dhammapada-reflections\" />"

      CSV.foreach('verseindex.csv') do |row|
        playorder += 1
        ret += "<navPoint id=\"nav#{playorder}\" playOrder=\"#{playorder}\">\n"
        ret += "<navLabel><text>#{row[1]}</text></navLabel>\n"
        ret += "<content src=\"Text/versepages.xhtml#{row[0]}\"/>"
        ret += "</navPoint>\n"
      end

      ret += "</navPoint>"

      ret
    end

    def verseindex_as_ul
      require 'csv'

      ret = []

      ret << "<ul class='verseindex'>"
      CSV.foreach('verseindex.csv') do |row|
        ret << "<li><a href='../Text/versepages.xhtml#{row[0]}'>#{row[1]}</a></li>"
      end
      ret << "</ul>"

      ret.join("\n")
    end

  end
end

