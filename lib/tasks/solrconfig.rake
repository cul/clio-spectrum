namespace :solr do
  namespace :jetty do
    desc "copy config and start jetty"
    task :start do
      cp_cmd = "cp -v " + File.join(Rails.root, "config", "solr_config", "*") + " " + File.join(Rails.root, "jetty", "solr", "conf/")
      system(cp_cmd)
      
      jetty_cmd = "cd " + File.join(Rails.root, "jetty") + " && java -jar start.jar"
      exec(jetty_cmd)
    end

    desc "remove data from pocket jetty"
    task :clear do
      rm_cmd = "rm -rf " + File.join(Rails.root, "jetty", "solr", "data")
      system(rm_cmd)
    end
  end
end
