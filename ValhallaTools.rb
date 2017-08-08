require 'mixlib/shellout'
require 'httparty'
class ValhallaClientManager
    include HTTParty
    base_uri '192.168.0.18:8787'
    # default_params :output => 'json'
    format :json
    # attr_accessor :r
    def initialize

        self
    end
    def getTime
        @r['trip']['summary']['time']
    end

    def getDuration
        @r['trip']['summary']['length']
    end

    def getTrip(params)
        url_q = '/route?json={"locations":[{"lat":'+"#{params[:org_lat]}"+',"lon":'+"#{params[:org_lon]}"+',"type":"break"},{"lat":'+"#{params[:dest_lat]}"+',"lon":'+"#{params[:dest_lon]}"+',"type":"break"}],"costing":"auto","directions_options":{"units":"miles"}}'#q
        puts "url_q: #{url_q}"
        @r = self.class.get(url_q)
        puts "r: #{@r}"
        if @r.success?
            true
            # self.r
        else
            raise @r.response
        end
    end

   

end


class ValhallaEventManager
    def initialize(params)
        @org_lat_field = params[:org_lat_field] 
        @org_lon_field = params[:org_lon_field] 
        @dest_lat_field = params[:dest_lat_field]
        @dest_lon_field = params[:dest_lon_field]            
    end
    
    def parseLine lu
        # puts lu
        @line = lu
        # @parsed = @line.split(',') 
        @org_lat = @line[@org_lat_field]
        @org_lon = @line[@org_lon_field]
        @dest_lat = @line[@dest_lat_field]
        @dest_lon = @line[@dest_lon_field]
    end


    def getOrgLat
        # 40.76724
        @org_lat
    end

    def getOrgLon
        # -73.97153
        @org_lon
    end

    def getDestLat
        # 41.26141
        @dest_lat
    end

    def getDestLon
        # -73.38822
        @dest_lon
    end

    def getLine
        puts "returning line"
        return @line
    end

    def addToLine(params)
        # if [pa]
        # params.each do |pa|
        # puts "params for wach #{pa}"
        @line[32] = params[0]
        @line[33] = params[1]
        puts "@line. #{@line}"
        # end
    end

     def ValhallaEventManager.setLine(vem)
        # line << 
        return vem.getLine
    end
end



module ValhallaTools
    def ValhallaTools.processCSV(csvfile)
        # begin
            # f = File.open csvfile
            # ef = File.open("export_#{csvfile}","w")
            # ef.write("org_lat, org_lon, dest_lat, dest_lon, trip_time, trip_duration")
            # ef.write("\n")
            valhalla_event = ValhallaEventManager.new(id_field: 31,org_lat_field: 30, org_lon_field: 29, dest_lat_field: 27, dest_lon_field: 26)
            CSV.open("/home/ubuntu/exportdynamic_random_points_from_ny_with_latlng_pairs.csv","w") do |csv|
                CSV.foreach(csvfile) do |line|
                # while line = f.gets
                    puts line
                    # ef.write("\n")
                    valhalla_event.parseLine line 

                    valhalla_client = ValhallaClientManager.new 
                    orglat = valhalla_event.getOrgLat
                    begin
                        valhalla_client.getTrip(org_lat: orglat, org_lon: valhalla_event.getOrgLon, dest_lat: valhalla_event.getDestLat, dest_lon: valhalla_event.getDestLon)
                        trip_time = valhalla_client.getTime
                        trip_duration = valhalla_client.getDuration
                    rescue => exception
                        puts "inside exception"
                        trip_time = "na"
                        trip_duration = "na"
                    ensure
                        puts "inside ensure"
                        
                    end
                    # r.getTrip('route')
                    
                    valhalla_event.addToLine([trip_time,trip_duration])
                    
                        csv << ValhallaEventManager.setLine(valhalla_event)
                    # end
                    # puts "trip time: #{trip_time}, trip duration: #{trip_duration}"
                    # line_id = l.getlineId
                    # line[]
                    # ef.write("#{orglat}, #{l.getOrgLon}, #{l.getDestLat}, #{l.getDestLon}, #{trip_time}, #{trip_duration}")
                #    line <<  
                    end
                    
            # ensure
            #     f.close
            #     ef.closeq
            # end
        end
    end
end


ValhallaTools.processCSV("/home/ubuntu/rbproj/polydynamic_random_points_from_ny_with_latlng_pairs.csv")


# require 'csv'

# CSV.foreach("test.csv") do |line|
#     puts line    
#     # csv << ["test","t"]
# end