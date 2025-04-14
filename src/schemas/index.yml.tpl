{% for x in FOO | from_json %}{{ x.Name }}:
  $ref: "{{ x.Name }}.yml"
{% endfor %}