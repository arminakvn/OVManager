require 'mixlib/shellout'
require 'httparty'




module OSMDataManager
    FOLNAME = '/home/ubuntu/scripts/polyrema/'

    
    class OSMDataEvent
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

            puts "cliping based on the input extent"
            cmd = Mixlib::ShellOut.new("sudo osmconvert #{@baseosm} -B=#{ext} --complex-ways --drop-brokenrefs -o=#{FOLNAME}base-subtracted-extent.pbf")
            cmd.run_command
            if cmd.error!
                puts "couldnt subtract base based on oxtent"
            else
                @baseosm = "#{FOLNAME}base-subtracted-extent.pbf"
                puts "subtracted base on extent now base is #{@baseosm}"
            end


        end

        def processF f
            puts "processing #{f}, @baseosm #{@baseosm}"
            if ( f =~ /.*\b.poly$/ )# && (f =~ /flood/)!=0
                begin
                    
                    chpou = OSMDataManager.chainProcess(f, @baseosm)
                    
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
                
            end
        end

    end

    def OSMDataManager.chainProcess(f, baseosm)
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
    
    def OSMDataManager.findOSM(f,baseosm)
        if ( f =~ /.*.osm$/ )
            puts ".osm is at the end"
            cmd = Mixlib::ShellOut.new("sudo","osmconvert", baseosm, "--subtract","#{FOLNAME}#{f}","-o=#{FOLNAME}#{f.sub('.osm','')}-subtracted.osm")
            cmd.run_command
        end
    end

    def OSMDataManager.convBack f
        cmd = Mixlib::ShellOut.new("sudo","osmconvert","#{FOLNAME}#{f.sub('.osm','')}-subtracted.osm","-o=#{FOLNAME}floodin-subtracted.pbf")
        cmd.run_command
    end


    def OSMDataManager.removeOsm f
        cmd = Mixlib::ShellOut.new("sudo","rm","#{FOLNAME}#{f.sub('.osm','')}-subtracted.osm")
        cmd.run_command
    end

    def OSMDataManager.getDir
        Dir.foreach FOLNAME
    end

    def OSMDataManager.processSub(en)
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



m = OSMDataManager::OSMDataEvent.new "/home/ubuntu/data/us-northeast-latest.osm.pbf"
m.clipExtent("/home/ubuntu/scripts/bound/mapoly.poly")

e = OSMDataManager.getDir
e.each do |item|
    puts item
# end    
    next if item == '.' or item == '..'
    m.processF(item)
end



# 
ext = "/home/ubuntu/scripts/bound/mapoly.poly"
FOLNAME = '/home/ubuntu/scripts/polyrema/'
cmd = Mixlib:: ShellOut.new("sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf -B=#{ext} | sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf --subtract - -o=#{FOLNAME}rest-of-subtr-northeast.pbf")
cmd.run_command