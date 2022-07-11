from jinja2 import Environment, PackageLoader

def query(name, params):
    env = Environment(loader=PackageLoader("glam.api", "query_templates"))
    main_sql = env.get_template(f"{name}.tpl")
    return main_sql.render(**params)
