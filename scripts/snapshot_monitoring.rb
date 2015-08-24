require 'pgstgtool'

warn_threshold = 70 #0.8 %
crit_threshold = 85 #0.9 %

MIN = 30 #seconds

@lvm = Pgstgtool::Lvm.new



def crit_threshold_breached(snapshot)
  @lvm.delete_snapshot(snapshot)
end

def warn_threshold_breached(snapshot)
  #do nothing
end

while true do
  snapshots = @lvm.get_all_snapshots
  snapshots.keys.each do |snapshot|
    puts snapshot
    if snapshot =~ /.*_pgstg$/
      if snapshots[snapshot]['data_percent'].to_i > crit_threshold
        puts "Critical threshold for snapshot breached (Threshold: #{crit_threshold.to_i}). #{snapshot} percent used space #{snapshots[snapshot]['data_percent'].to_i}. Deleting snapshot"
        crit_threshold_breached(snapshot)
      elsif snapshots[snapshot]['data_percent'].to_i > warn_threshold
        #puts "Warning threshold for snapshot breached (Threshold: #{warn_threshold.to_i}). #{snapshot} percent used space #{snapshots[snapshot]['data_percent'].to_i}."
        warn_threshold_breached(snapshot)
      end 
    end
  end
  sleep MIN
end


