require 'mixlib/shellout'
require 'httparty'




module OVManager
    FOLNAME = '/home/ubuntu/scripts/polyrema/'

    
    class OVMevent
        def initialize(baseosm)
            @baseosm = baseosm
            @delbase = 'pass'
        end


        def appendBackExtent(baseosm,ext)
            cmd = Mixlib::ShellOut.new("sudo osmconvert #{baseosm} -B=#{ext} --complex-ways --drop-brokenrefs | sudo osmconvert #{baseosm} --subtract - -o=#{FOLNAME}base-subtracted-rest.pbf")
            cmd.run_command
        end
        

        def clipExtent(ext)
            @ext = ext
            # -73.7680759429931641,40.7721142524021047,-73.7635024225405402,40.7788583940547440

            # first clip this out to the location 
            puts "cliping based on the input extent"
            cmd = Mixlib::ShellOut.new("sudo osmconvert #{@baseosm} -B=#{ext} --complex-ways --drop-brokenrefs -o=#{FOLNAME}base-subtracted-extent.pbf")
            cmd.run_command
            if cmd.error!
                puts "couldnt subtract base based on oxtent"
            else
                @baseosm = "#{FOLNAME}base-subtracted-extent.pbf"
                puts "subtracted base on extent now base is #{@baseosm}"
            end

            # cmd = Mixlib:: ShellOut.new("sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf -B=#{ext} | sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf --subtract - -o=#{FOLNAME}rest-of-subtr-northeast#{ext}.pbf")


        end

        def processF f
            puts "processing #{f}, @baseosm #{@baseosm}"
            if ( f =~ /.*\b.poly$/ )# && (f =~ /flood/)!=0
                begin
                    
                    chpou = OVManager.chainProcess(f, @baseosm)
                    
                rescue => exception

                    puts " error in processing, will keep the base and pass"
                    @delbase = 'pass'

                else
                    if (@baseosm == "/home/ubuntu/data/us-northeast-latest.osm.pbf")
                        puts "it was the base northeast osm dont delete prev"
                        @baseosm = "#{chpou}"
                        @delbase = 'pass'
                    elsif (@baseosm == "base-subtracted-extent.pbf")
                        puts "it was the base extent dont delete prev"
                        @baseosm = "#{chpou}"
                        @delbase = 'pass'
                    else
                        
                        @delbase = "#{@baseosm}"
                        @baseosm = "#{chpou}"
                        # if cmd.error!
                        #     puts "couldnt delete prev but setting the base "
                        #     @baseosm = "#{chpou}"
                        # else
                        #     puts "deleted previous"
                        #     @baseosm = "#{chpou}"
                        # end
                    end
                    
                ensure
                    puts "this is ensure"
                    if @delbase == 'pass'
                        puts "ensudere passes"
                    else 
                        puts "ensure deletes"
                        cmd = Mixlib::ShellOut.new("sudo rm #{@delbase}")
                        cmd.run_command
                    end
                    
                    
                end

                
                
                puts "chain process returns #{chpou}"
                
                # puts "output: #{FOLNAME}#{f.sub('.poly','')}_floodin-subtracted.pbf"
            end
        end

    end

    def OVManager.chainProcess(f, baseosm)
        puts "chain process"
        cmd = Mixlib::ShellOut.new("sudo osmconvert #{baseosm} -B=#{FOLNAME}#{f.sub('.poly','')}.poly --complex-ways --drop-brokenrefs | sudo osmconvert #{baseosm} --subtract - -o=#{FOLNAME}#{f.sub('.poly','')}_floodin-subtracted.pbf")
        cmd.run_command
        puts "#{cmd.stdout}"
        puts "#{cmd.stderr}"
        if cmd.error!
            return "#{baseosm}"
        else
            return "#{FOLNAME}#{f.sub('.poly','')}_floodin-subtracted.pbf"
        end
    end
    
    def OVManager.findOSM(f,baseosm)
        if ( f =~ /.*.osm$/ )
            puts ".osm is at the end"
            cmd = Mixlib::ShellOut.new("sudo","osmconvert", baseosm, "--subtract","#{FOLNAME}#{f}","-o=#{FOLNAME}#{f.sub('.osm','')}-subtracted.osm")
            cmd.run_command
        end
    end

    def OVManager.convBack f
        cmd = Mixlib::ShellOut.new("sudo","osmconvert","#{FOLNAME}#{f.sub('.osm','')}-subtracted.osm","-o=#{FOLNAME}floodin-subtracted.pbf")
        cmd.run_command
    end


    def OVManager.removeOsm f
        cmd = Mixlib::ShellOut.new("sudo","rm","#{FOLNAME}#{f.sub('.osm','')}-subtracted.osm")
        cmd.run_command
    end

    def OVManager.getDir
        Dir.foreach FOLNAME
    end

    def OVManager.processSub(en)
        en.each do |item|
            next if item == '.' or item == '..' or item =~ /.*.osm$/
            pname = item.sub('.poly','')
            puts pname    
            cmd = Mixlib::ShellOut.new("sudo","osmconvert", "/home/ubuntu/data/us-northeast-latest.pbf", "-B=#{FOLNAME}#{pname}.poly","--complex-ways","--drop-brokenrefs","-o=#{FOLNAME}flood_#{pname}.osm")
            cmd.run_command
            puts cmd.stdout
        end
        
    end

end






# cmd = Mixlib:: ShellOut.new("sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf -b=-73.7680759429931641,40.7721142524021047,-73.7635024225405402,40.7788583940547440 --complex-ways --drop-brokenrefs | sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf --subtract - | sudo osmconvert - #{FOLNAME}195_floodin-subtracted.pbf -o=#{FOLNAME}out-northeast.pbf")
ext = "/home/ubuntu/scripts/bound/mapoly.poly"
FOLNAME = '/home/ubuntu/scripts/polyrema/'
cmd = Mixlib:: ShellOut.new("sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf -B=#{ext} | sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf --subtract - -o=#{FOLNAME}rest-of-subtr-northeast.pbf")

cmd.run_command

m = OVManager::OVMevent.new "/home/ubuntu/data/us-northeast-latest.osm.pbf"
m.clipExtent("/home/ubuntu/scripts/bound/mapoly.poly")
# -73.7680759429931641,40.7721142524021047,-73.7635024225405402,40.7788583940547440
# the first thing is that to just clip from the extent of the poly files // a polygon input to 
# then merge back with the northeast so not to work on the entire notheast file

#m.processF('000100.poly')


e = OVManager.getDir
e.each do |item|
    puts item
# end    
    next if item == '.' or item == '..'
    m.processF(item)
end