#encoding: utf-8
require 'optparse'
require 'json'
require 's3'
require 'uri'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-f",  "config file") do |f|
    options[:config] =f 
  end
  opts.on("--dryrun","Displays the operations that would be performed using the specified command without actually running them.")  do |v|
      options[:dryrun] = true
  end

  opts.on("--repo","local git repo")  do |v|
      options[:repo] = v
  end
  opts.on("")
end.parse!

options[:config] ||= "config.json"
unless File.exist?(options[:config])
    p  "no config file"
    exit
end


#從s3上取得上次部署的version
def find_version(bucket)
    begin
        object = bucket.objects.find("version.s3")
    rescue
        return "" 
    end
    return object.content.strip
end

#部署完成後，把此次的版本給上傳
def update_version(bucket,hash)
    object = bucket.objects.build("version.s3")
    object.content= hash
    object.save
end

config = JSON.load(open(options[:config]))
service = S3::Service.new(:access_key_id => config["aws"]["accessKeyID"], :secret_access_key => config["aws"]["accesskey"])
s3bucket=service.buckets.find(config["aws"]["bucket"])
deployed_commit=find_version(s3bucket)  #上一次部署的commit
target_commit="HEAD"
git_repo= options[:repo] || config["repo"]

if deployed_commit== ""
    #進行全部上傳
else
    #進行部份上傳
    cmd = "cd #{git_repo}  &&  git diff --name-status   #{deployed_commit}  #{target_commit}"
    p cmd
    output = ` cd #{git_repo}  &&  git diff --name-status   #{deployed_commit}  #{target_commit}    `
    output.each_line do |line|
        action,file = line.split(" ")
        action.strip!
        file.strip!
        if(action=='M' ||action=='A')
            if options[:dryrun]==true
                p  "(dryrun) upload "+file
            else
                print  "upload "+file +"\n"
                new_object = s3bucket.objects.build(file)
                new_object.content = open(git_repo+"/"+file)
                new_object.save
            end
        elsif action=='D'
            if options[:dryrun] == true
                p "(dryrun) delete "+file
            else
                print "delete "+file +"\n"
                begin
                object=s3bucket.objects.find(file)
                object.destroy
                rescue
                    p "file is not exists"
                end
            end
        else 
        p  "unknow action "
        exit
        
        end
    end
end


cmd = "cd #{git_repo}  && git rev-parse HEAD"
deployed_commit = `#{cmd}`
deployed_commit.strip!
p  "commit: #{deployed_commit} deployed"
update_version(s3bucket,deployed_commit)  unless options[:dryrun]
