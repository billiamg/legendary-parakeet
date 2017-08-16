#now = %x|ssh admin@192.168.0.1 bwdpi stat -m traffic -u realtime | .split(/\n/)
require "bundler"
Bundler.require
require "pp"

statsd = Datadog::Statsd.new('localhost', 8125)

def get_bw_data
data_hash = {}
mapping = {
	"00:25:22:FD:13:B5" => "Jupiter",
	"C8:60:00:CC:F6:17" => "SKYNET",
	"D0:50:99:AA:54:AB" => "TEDZILLA",
	"E8:94:F6:03:12:A9" => "bwen-PC",
	"D0:73:D5:00:2E:15" => "LIFX Bulb",
	"6C:AD:F8:5A:62:C6" => "Chromecast",
	"D0:73:D5:03:49:04" => "LIFX Bulb",
	"00:25:4B:00:1C:71" => "bwen-airport-express",
	"00:1F:D0:81:B7:F4" => "SOLAR",
	"08:00:27:BB:80:95" => "chopsticks",
	"F4:F5:D8:07:DD:CC" => "Chromecast",
	"74:81:14:28:B7:5A" => "iPad",
	"B8:E8:56:08:5C:62" => "Brendans-MBA",
	"E0:AC:CB:34:D7:E4" => "WillsAppleWatch",
	"34:A3:95:70:95:17" => "iPhoneWill",
	"D0:73:D5:03:19:1C" => "LIFX Bulb",
	"54:9F:13:73:61:CC" => "iPhone-6",
	"CC:44:63:14:A7:4B" => "Teds-iPhone",
	"D0:73:D5:02:2F:23" => "LIFX Bulb",
	"D0:73:D5:14:AB:D8" => "LIFX Z",
	"D0:73:D5:12:49:15" => "LIFX Bulb",
	"3C:15:C2:BB:FE:86" => "Teds-MBP",
	"D0:73:D5:00:FC:3A" => "LIFX Bulb",
	"D0:73:D5:00:A9:D9" => "LIFX Bulb",
	"74:8D:08:E4:3F:38" => "Bwens-iPhone",
	"D0:73:D5:14:5F:8F" => "LIFX Bulb",
	"00:26:BB:07:01:14" => "Will-MBP"
	}
rawoutput = %x|ssh admin@192.168.0.1 bwdpi stat -m traffic -u realtime | .split(/\n/)
	rawoutput.each do |line|
		if line.match(/mac= /i)
			mac = /([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})/.match(line)[0]
        		client = mapping[mac] || mac
			down = /\d{1,}$/.match(line)[0]
       			up = /\d{1,}(?=\/)/.match(line)[0]
			data_hash[client] = [down.to_i, up.to_i]
		end
	end	
data_hash
end

interval = "10".to_i

next_refresh = Time.at(0)

last = get_bw_data

loop do
	if Time.now > next_refresh
	end

	time = Time.now
pp time 
	begin
		now = get_bw_data
pp now
		output = Hash[now.map do |client, now_values|
pp now_values
			deltas = now_values.map do |key, now_value|
pp deltas
pp now_value
pp key
				[key, [0, now_value - last.fetch(client, {}).fetch(key, 0)].max]
			end
			[client, Hash[deltas]]
		end]

		output.each do |client, values|
			tags = ["hostname:#{client}"]
			statsd.batch do |s|
				values.each do |key, value|
					s.count(key, value, tags: tags)			
				end
			end
		end
		puts JSON.dump(output)
		last = now
	end
p "before sleep"
	sleep [time + interval - Time.now, 0].max

end



