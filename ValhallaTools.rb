require 'mixlib/shellout'
require 'httparty'


class ValhallaClientManager
    include HTTParty
    base_uri '128.31.25.188:8002' #http://128.31.25.188:8002 #52.170.86.125:8002
    # default_params :output => 'json'
    format :json
    # attr_accessor :r
    def initialize

        self
    end

    def decodeShape
        Polylines::Decoder.decode_polyline(@r['trip']['legs'][0]['shape'],percision=1e6)
    end

    def getTripShape
        @r['trip']['legs'][0]['shape']
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
        @line = lu
        @org_lat = @line[@org_lat_field]
        @org_lon = @line[@org_lon_field]
        @dest_lat = @line[@dest_lat_field]
        @dest_lon = @line[@dest_lon_field]
    end


    def getOrgLat
        @org_lat
    end

    def getOrgLon
        @org_lon
    end

    def getDestLat
        @dest_lat
    end

    def getDestLon
        @dest_lon
    end

    def getLine
        puts "returning line"
        return @line
    end

    def addToLine(params)
        @line[32] = params[0]
        @line[33] = params[1]
        puts "@line. #{@line}"
    end

     def ValhallaEventManager.setLine(vem)
        return vem.getLine
    end
end



module ValhallaTools
    def ValhallaTools.processCSV(csvfile, fieldmap, outname)
            valhalla_event = ValhallaEventManager.new(id_field: fieldmap[:id_field], org_lat_field: fieldmap[:org_lat_field], org_lon_field: fieldmap[:org_lon_field],dest_lat_field: fieldmap[:dest_lat_field], dest_lon_field: fieldmap[:dest_lon_field])
        CSV.open("expo_#{outname}.csv","w") do |csv|
            CSV.foreach(csvfile) do |line|
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
                valhalla_event.addToLine([trip_time,trip_duration])
                csv << ValhallaEventManager.setLine(valhalla_event)
            end
        end
    end
end



fieldmap = {:id_field => 0, :org_lat_field => 6, :org_lon_field => 5, :dest_lat_field => 3, :dest_lon_field =>2}

ValhallaTools.processCSV("/home/ubuntu/scripts/to_suffolk.csv",fieldmap,"TOsuffolkSIMhalf")