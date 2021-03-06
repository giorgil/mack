require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent.parent + 'spec_helper'

describe Mack::Request::UploadedFile do
  
  before(:each) do
    FileUtils.cp(Mack::Paths.images("logo.gif"), 
                 Mack::Paths.public("something", "logo.gif"))
    @uploaded_file = 
    Mack::Request::UploadedFile.new(:type => "image/gif", 
                                    :filename => "logo.gif", 
                                    :head => "Content-Disposition: form-data; name=\"my_new_file\"; filename=\"logo.gif\"\r\nContent-Type: image/gif\r\n", 
                                    :tempfile => File.open(Mack::Paths.public("something", "logo.gif")), 
                                    :name=>"my_new_file")
  end
  
  after(:each) do
    FileUtils.rm_rf(Mack::Paths.tmp)
  end
  
  it "should be able to save to..." do
    @uploaded_file.save_to(Mack::Paths.tmp(@uploaded_file.file_name))
    File.exists?(Mack::Paths.tmp(@uploaded_file.file_name)).should == true
    File.exists?(@uploaded_file.temp_file.path).should_not == true
  end
  
  it "should be able to save to... (path constructed with array)" do
    @uploaded_file.save_to([Mack.root, "tmp", @uploaded_file.file_name])
    File.exists?(Mack::Paths.tmp(@uploaded_file.file_name)).should == true
    File.exists?(@uploaded_file.temp_file.path).should_not == true
  end
  
  it "should be able to save to... (path constructed with implied array)" do
    @uploaded_file.save_to(Mack.root, "tmp", @uploaded_file.file_name)
    File.exists?(Mack::Paths.tmp(@uploaded_file.file_name)).should == true
    File.exists?(@uploaded_file.temp_file.path).should_not == true
  end
  
  it "should have correct destination path" do
    @uploaded_file.destination_path = File.join("foo", "bar")
    @uploaded_file.destination_path.should == "foo/bar"
    @uploaded_file.destination_path = ["foo", "bar"]
    @uploaded_file.destination_path.should == "foo/bar"
    @uploaded_file.destination_path = "pickled", "eggs"
    @uploaded_file.destination_path.should == "pickled/eggs"
  end
  
  it "should be able to save" do
    path = Mack::Paths.tmp(@uploaded_file.file_name)
    @uploaded_file.destination_path = path
    @uploaded_file.save
    File.exists?(Mack::Paths.tmp(@uploaded_file.file_name)).should == true
    File.exists?(@uploaded_file.temp_file.path).should_not == true
  end
    
  it "should raise error when destination path is not specified" do
    lambda { @uploaded_file.save }.should raise_error(ArgumentError)
  end
  
end
