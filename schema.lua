return {
  no_consumer = true,
  fields = {

    current_value = {
      type = "table",
      schema = {
        fields = {
          current_value_type = {type = "string", required = true, enum = {"body", "headers", "querystring"}},
          json_path_or_header_name_or_querystring = {type = "string", required = false}
        }
      }
    },
    value_check = {
      type = "table",
      schema = {
        fields = {
          value_check_type = {
            type = "string",
            required = true,
            enum = {"exists", "missing", "equals", "match expression"}
          },
          value = {type = "string", required = false}
        }
      }
    },
    upstream = {
      type = "table",
      schema = {
        fields = {
          host = {type = "string", required = true},
          port = {type = "number", required = false},
          path = {type = "string", required = false}
        }
      }
    }
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    return true
  end
}
