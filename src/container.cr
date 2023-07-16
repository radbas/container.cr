abstract class Radbas::Container
  VERSION = "0.1.0"

  private CONFIG  = {autowire: false}
  private ENTRIES = {} of Nil => Nil

  # set autowire flag
  private macro autowire(flag = true)
    {% CONFIG[:autowire] = flag %}
  end

  # register a container entry
  private macro register(entry, params = nil, factory = nil, public = false)
    {% raise "[container:register] #{entry} is not a valid path" unless entry.is_a?(Path) %}
    {% resolved_entry = entry.resolve? %}
    {% raise "[container:register] #{entry} could not be resolved, did you require it?" unless resolved_entry %}
    {% raise "[container:register] params for #{resolved_entry} must be a named Tuple" if !params.nil? && !params.is_a?(NamedTupleLiteral) %}
    {% raise "[container:register] abstract #{resolved_entry} must be registered with a factory" if resolved_entry.abstract? && factory.nil? %}
    {% raise "[container:register] factory for #{resolved_entry} must be a valid call or proc" if !factory.nil? && !(factory.is_a?(Call) || factory.is_a?(ProcLiteral)) %}
    {% ENTRIES[resolved_entry] = {params: params, factory: factory, public: public} %}
  end

  # register all children of an abstract parent class
  private macro softmap(parent, params = nil, public = false)
    {% raise "[container:softmap] #{parent} is not a valid path" unless parent.is_a?(Path) %}
    {% resolved_parent = parent.resolve? %}
    {% raise "[container:softmap] #{parent} could not be resolved, did you require it?" unless resolved_parent %}
    {% raise "[container:softmap] #{resolved_parent} must be abstract" unless resolved_parent.abstract? %}
    {% raise "[container:softmap] params for #{resolved_parent} must be a named Tuple" if !params.nil? && !params.is_a?(NamedTupleLiteral) %}
    {% for cl in resolved_parent.all_subclasses.select { |c| c.class? && !c.abstract? } %}
      {% ENTRIES[cl] = {params: params, factory: nil, public: public} unless ENTRIES[cl] %}
    {% end %}
  end

  # build container entries
  private macro finished

    {% for entry, config in ENTRIES %}

      {% params = config[:params] %}
      {% factory = config[:factory] %}
      {% public = config[:public] %}

      {% new_args = [] of Nop %}

      {% unless factory %}

        {% init_func = entry.methods.find(&.name.==("initialize")) %}
        {% init_args = init_func ? init_func.args : [] of Nop %}

        {% for arg in init_args %}
          {%
            new_arg = {
              name:  arg.name,
              id:    arg.restriction,
              value: arg.default_value,
            }
          %}
          {% config_arg = params ? params[arg.name] : nil %}
          {% unless config_arg.nil? %}
            {% if config_arg.is_a?(Call) %}
              {% raise "[container:build] param #{arg.name} of #{entry} uses a non valid call, use get" unless config_arg.name == "get" && config_arg.receiver.nil? %}
              {% new_arg[:id] = config_arg.args[0] %}
            {% else %}
              {% new_arg[:id] = nil %}
              {% new_arg[:value] = config_arg %}
            {% end %}
          {% end %}

          {% if new_arg[:id] %}
            {% raise "[container:build] dependency #{new_arg[:id]} of #{entry} is not a valid path" unless new_arg[:id].is_a?(Path) %}
            {% resolved_dep = new_arg[:id].resolve? %}
            {% raise "[container:build] dependency #{new_arg[:id]} of #{entry} could not be resolved, did you require it?" unless resolved_dep %}
            {% new_arg[:id] = resolved_dep %}
            {% unless ENTRIES[resolved_dep] %}
              {% if new_arg[:value].nil? %}
                {% raise "[container:build] #{entry} uses #{resolved_dep} which is not registered and autowire is off" unless CONFIG[:autowire] %}
                {% raise "[container:build] autowired #{resolved_dep} of #{entry} must not be an interface" if resolved_dep.abstract? %}
                {% ENTRIES[resolved_dep] = {args: nil, factory: nil, public: false} %}
              {% else %}
                {% new_arg[:id] = nil %}
              {% end %}
            {% end %}
          {% elsif new_arg[:value].nil? %}
            {% raise "[container:build] unable to resolve param < #{new_arg[:name]} : #{new_arg[:id]} > for #{entry}" %}
          {% end %}

          {% new_args << new_arg %}
        {% end %}

      {% else %}
            {% if factory.is_a?(Call) && factory.name == "get" && factory.receiver.nil? %}
              {% raise "[container:build] implementation #{factory.args[0]} of #{entry} is not a valid path" unless factory.args[0].is_a?(Path) %}
              {% resolved_impl = factory.args[0].resolve? %}
              {% raise "[container:build] implementation #{factory.args[0]} of #{entry} could not be resolved, did you require it?" unless resolved_impl %}
              {% raise "[container:build] #{resolved_impl} does not implement #{entry}" unless entry.all_subclasses.includes?(resolved_impl) %}
              {% unless ENTRIES[resolved_impl] %}
                {% raise "[container:build] #{entry} uses implementation #{resolved_impl} which is not registered and autowire is off" unless CONFIG[:autowire] %}
                {% ENTRIES[resolved_impl] = {params: nil, factory: nil, public: false} %}
              {% end %}
              {% factory = "_#{resolved_impl.name.split("::").join("_").id}" %}
            {% end %}
      {% end %}

      {% entry_name = "_#{entry.name.split("::").join("_").id}" %}

      @{{entry_name.id}}_resolving = false
      private getter {{entry_name.id}} : {{entry.id}} {
        raise "[container:get] circular reference detected for {{entry.id}}" if @{{entry_name.id}}_resolving
        @{{entry_name.id}}_resolving = true
        {% if factory %}
          {% if factory.is_a?(ProcLiteral) %}
            {{factory.id}}.call(self)
          {% else %}
            {{factory.id}}
          {% end %}
        {% elsif new_args.empty? %}
          {{entry.id}}.new
        {% else %}
          init_params = {
            {% for arg in new_args %}
              {% if arg[:id] %}
                {% get_name = "_#{arg[:id].name.split("::").join("_").id}" %}
                {{arg[:name].id}} = {{get_name.id}},
              {% else %}
                {{arg[:name].id}} = {{arg[:value].id}},
              {% end %}
            {% end %}
          }
          entry = {{entry.id}}.new(*init_params)
          @{{entry_name.id}}_resolving = false
          entry
        {% end %}
      }

      {% unless public %} protected {% end %} def get(id : {{entry.id}}.class) : {{entry.id}}
        raise "[container:get] trying to get {{entry.id}} with subclass #{id}, did you forget to register it?" unless id == {{entry.id}}
        {{entry_name.id}}
      end

    {% end %}
    {% ENTRIES.clear %}
  end
end
