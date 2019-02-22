

Here's where we keep the master copy of CLIO's Solr configuration files.
This'll be safely within the clio-spectrum github repo.

Here's how you might update the configuration for your SolrCloud cluster:

(Step 0 - make edits to the config files)

(Step 1 - upload the new config, overwriting the current config)
daisy:clio-spectrum marquis$ solr zk upconfig -zkhost localhost:2181/solr/test -confdir config/solr/configsets/clio -confname clio 
INFO  - 2019-02-15 14:04:42.025; org.apache.solr.util.configuration.SSLCredentialProviderFactory; Processing SSL Credential Provider chain: env;sysprop
Uploading /Users/marquis/src/clio-spectrum/config/solr/configsets/clio/conf for config clio to ZooKeeper at localhost:2181/solr/test

This assume that:
- You've got an ssh tunnel setup to connect to the Zookeeper servers.
  See the SysAdmin wiki page for hints.
- You have the full Solr installation sitting around somewhere, which it's 
  management script "solr" in your path.  Homebrew can do this for you.

Note that we're passing the path arg to the Zookeeper host arg - set this appropriately.

(Step 2 - reload the collection so that it reads the new config files)
daisy:clio-spectrum marquis$ curl 'http://localhost:12301/solr/admin/collections?action=RELOAD&name=clio'  

This should report back on each node that we reloaded.

(Step 3 - if you updated any indexing rules, you'll need to reindex!)


Port-restricting firewalls and unroutable networks protect us from
anyone directly accessing our Solr servers.  
But we should also add Solr-level security.



