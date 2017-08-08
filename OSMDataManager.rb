require 'mixlib/shellout'
require 'httparty'


module OSMDataManager



    def OSMDataManager.chainProcess(f, baseosm)
        puts "chain process"
        cmd = Mixlib::ShellOut.new("sudo osmconvert #{baseosm} -B=#{fOLNAME}#{f.sub('.poly','')}.poly --complex-ways --drop-brokenrefs | sudo osmconvert #{baseosm} --subtract - -o=#{fOLNAME}#{f.sub('.poly','')}_floodin-subtracted.pbf")
        cmd.run_command
        puts "#{cmd.stdout}"
        puts "#{cmd.stderr}"
        if cmd.error!
            return "#{baseosm}"
        else
            return "#{fOLNAME}#{f.sub('.poly','')}_floodin-subtracted.pbf"
        end
    end
    
    def OSMDataManager.findOSM(f,baseosm)
        if ( f =~ /.*.osm$/ )
            puts ".osm is at the end"
            cmd = Mixlib::ShellOut.new("sudo","osmconvert", baseosm, "--subtract","#{fOLNAME}#{f}","-o=#{fOLNAME}#{f.sub('.osm','')}-subtracted.osm")
            cmd.run_command
        end
    end

    def OSMDataManager.convBack f
        cmd = Mixlib::ShellOut.new("sudo","osmconvert","#{fOLNAME}#{f.sub('.osm','')}-subtracted.osm","-o=#{fOLNAME}floodin-subtracted.pbf")
        cmd.run_command
    end


    def OSMDataManager.removeOsm(f,fOLNAME)
        cmd = Mixlib::ShellOut.new("sudo","rm","#{fOLNAME}#{f.sub('.osm','')}-subtracted.osm")
        cmd.run_command
    end

    def OSMDataManager.getDir fOLNAME
        Dir.foreach fOLNAME
    end

    def OSMDataManager.processSub(en)
        en.each do |item|
            next if item == '.' or item == '..' or item =~ /.*.osm$/
            pname = item.sub('.poly','')
            puts pname    
            cmd = Mixlib::ShellOut.new("sudo","osmconvert", "/home/ubuntu/data/us-northeast-latest.pbf", "-B=#{fOLNAME}#{pname}.poly","--complex-ways","--drop-brokenrefs","-o=#{fOLNAME}flood_#{pname}.osm")
            cmd.run_command
            puts cmd.stdout
        end
        
    end



    class OSMDataEvent
        attr_reader :fOLNAME
        def initialize(inFoldername,baseosm)
            @baseosm = baseosm
            @delbase = 'pass'
            @fOLNAME = inFoldername
        end


        def appendBackExtent(baseosm,ext)
            cmd = Mixlib::ShellOut.new("sudo osmconvert #{baseosm} -B=#{ext} --complex-ways --drop-brokenrefs | sudo osmconvert #{baseosm} --subtract - -o=#{@fOLNAME}base-subtracted-rest.pbf")
            cmd.run_command
        end
        

        def clipExtent(ext)
            @ext = ext

            puts "cliping based on the input extent"
            cmd = Mixlib::ShellOut.new("sudo osmconvert #{@baseosm} -B=#{ext} --complex-ways --drop-brokenrefs -o=#{@fOLNAME}base-subtracted-extent.pbf")
            cmd.run_command
            if cmd.error!
                puts "couldnt subtract base based on oxtent"
            else
                @baseosm = "#{@fOLNAME}base-subtracted-extent.pbf"
                puts "subtracted base on extent now base is #{@baseosm}"
            end


        end



        def go
            e = OSMDataManager.getDir @fOLNAME
            e.each do |item|
                puts item
                next if item == '.' or item == '..'
                m.processF(item)
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



end

# example usage for where the base osm is "/home/ubuntu/data/us-northeast-latest.osm.pbf",

m = OSMDataManager::OSMDataEvent.new('/home/ubuntu/scripts/polyrema/',"/home/ubuntu/data/us-northeast-latest.osm.pbf")

m.clipExtent("/home/ubuntu/scripts/bound/mapoly.poly")

m.go



# shorthand for generating a osm file of the rest of the area after clipping to a smaller extent (e.g. to attach it back in to the northeast area file)
ext = "/home/ubuntu/scripts/bound/mapoly.poly"
@fOLNAME = '/home/ubuntu/scripts/polyrema/'
cmd = Mixlib:: ShellOut.new("sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf -B=#{ext} | sudo osmconvert /home/ubuntu/data/us-northeast-latest.osm.pbf --subtract - -o=#{@fOLNAME}rest-of-subtr-northeast.pbf")
cmd.run_command