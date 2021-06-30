require 'hubspot-ruby'

namespace :hubspot do
  desc 'Dump properties to file'
  task :dump_properties, [:kind, :file, :hapikey, :include, :exclude] do |_, args|
    hapikey = args[:hapikey] || ENV['HUBSPOT_API_KEY']
    kind = args[:kind]
    klass = get_klass(kind)
    props = Hubspot::Utils::dump_properties(klass, hapikey, build_filter(args))
    if args[:file].blank?
      puts JSON.pretty_generate(props)
    else
      File.open(args[:file], 'w') do |f|
        f.write(JSON.pretty_generate(props))
      end
    end
  end

  desc 'Restore properties from file'
  task :restore_properties, [:kind, :file, :hapikey, :dry_run] do |_, args|
    hapikey = args[:hapikey] || ENV['HUBSPOT_API_KEY']
    if args[:file].blank?
      raise ArgumentError, ':file is a required parameter'
    end
    kind = args[:kind]
    klass = get_klass(kind)
    file = File.read(args[:file])
    props = JSON.parse(file)
    Hubspot::Utils.restore_properties(klass, hapikey, props, args[:dry_run] != 'false')
  end

  desc 'Delete all properties'
  task :delete_all_properties, [:kind, :hapikey, :dry_run] do |_, args|
    hapikey = args[:hapikey] || ENV['HUBSPOT_API_KEY']
    kind = args[:kind]
    klass = get_klass(kind)
  
    Hubspot::Utils.with_hapikey(hapikey) do
      klass.all.each do |p|
        print p['name']
        if args[:dry_run] != 'false'
          puts ' --dry'
        else
          puts (Hubspot::ContactProperties.delete!(p['name']) unless p['readOnlyDefinition'] rescue ' --no')
        end
      end
    end
  end


  private

  def get_klass(kind)
    unless %w(contact deal company).include?(kind)
      raise ArgumentError, ':kind must be either "contact" or "deal" or "company"'
    end
    case kind
    when 'contact'
      Hubspot::ContactProperties
    when 'deal'
      Hubspot::DealProperties
    when 'company'
      Hubspot::CompanyProperties
    end
  end

  def build_filter(args)
    { include: val_to_array(args[:include]),
      exclude: val_to_array(args[:exclude])
    }
  end

  def val_to_array(val)
    val.blank? ? val : val.split(/\W+/)
  end
end
