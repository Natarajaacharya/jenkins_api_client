require File.expand_path('../spec_helper', __FILE__)
require "json"

describe JenkinsApi::Client::PluginManager do
  context "With properly initialized Client" do
    before do
      mock_logger = Logger.new "/dev/null"
      @client = mock
      @client.should_receive(:logger).and_return(mock_logger)
      @plugin = JenkinsApi::Client::PluginManager.new(@client)
      @installed_plugins = load_json_from_fixture("installed_plugins.json")
      @available_plugins = load_json_from_fixture("available_plugins.json")
      @updatable_plugins = load_json_from_fixture("updatable_plugins.json")
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instane of client object" do
          mock_logger = Logger.new "/dev/null"
          @client.should_receive(:logger).and_return(mock_logger)
          expect(
            lambda { JenkinsApi::Client::PluginManager.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#list_installed" do
        it "lists all installed plugins in jenkins" do
          @client.should_receive(:api_get_request).
            with("/pluginManager", "tree=plugins[shortName,version,bundled]").
            and_return(@installed_plugins)
          plugins = @plugin.list_installed
          plugins.class.should == Hash
          plugins.size.should == @installed_plugins["plugins"].size
        end
        it "lists all installed plugins except bundled ones in jenkins" do
          @client.should_receive(:api_get_request).
            with("/pluginManager", "tree=plugins[shortName,version,bundled]").
            and_return(@installed_plugins)
          @plugin.list_installed(true).class.should == Hash
        end
      end

      describe "#list_by_criteria" do
        supported_criteria = [
          "active", "bundled", "deleted", "downgradable", "enabled",
          "hasUpdate", "pinned"
        ]
        supported_criteria.each do |criteria|
          it "lists all installed plugins matching criteria '#{criteria}'" do
            @client.should_receive(:api_get_request).
              with("/pluginManager",
                "tree=plugins[shortName,version,#{criteria}]"
              ).and_return(@installed_plugins)
            plugins = @plugin.list_by_criteria(criteria).class.should == Hash
          end
        end
        it "raises an error if unsupported criteria is specified" do
          expect(
            lambda { @plugin.list_by_criteria("unsupported") }
          ).to raise_error(ArgumentError)
        end
      end

      describe "#list_available" do
        it "lists all available plugins in jenkins update center" do
          @client.should_receive(:api_get_request).
            with("/updateCenter/coreSource", "tree=availables[name,version]").
            and_return(@available_plugins)
          @plugin.list_available.class.should == Hash
        end
      end

      describe "#list_updates" do
        it "lists all available plugin updates in jenkins update center" do
          @client.should_receive(:api_get_request).
            with("/updateCenter/coreSource", "tree=updates[name,version]").
            and_return(@updatable_plugins)
          @plugin.list_updates.class.should == Hash
        end
      end

      describe "#install" do
        it "installs a single plugin given as a string" do
          @client.should_receive(:api_post_request).
            with("/pluginManager/install",
              {"plugin.awesome-plugin.default" => "on"}
            ).and_return("302")
          @plugin.install("awesome-plugin").to_i.should == 302
        end
        it "installs multiple plugins given as an array" do
          @client.should_receive(:api_post_request).
            with("/pluginManager/install",
              {
                "plugin.awesome-plugin-1.default" => "on",
                "plugin.awesome-plugin-2.default" => "on",
                "plugin.awesome-plugin-3.default" => "on"
              }
            ).and_return("302")
          @plugin.install([
            "awesome-plugin-1",
            "awesome-plugin-2",
            "awesome-plugin-3"
          ]).to_i.should == 302
        end
      end
    end
  end
end
