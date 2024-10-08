require "minitest/autorun"
require "squirtle"

class TestSquirtle < Minitest::Test
    SIMPLE_QUERY = "SELECT name, gender FROM employees WHERE salary > 60000 AND car_color='red' "
    def test_select
        assert(Squirtle.parse("SELECT * FROM table"))
    end

    def test_select_with_agg_fun
        assert(Squirtle.parse("SELECT SUM(salaries) FROM table"))
    end

    def test_select_with_nested_agg_fun
        assert(Squirtle.parse("SELECT COALESCE(MIN(salaries), 0) FROM employees"))
    end

    def test_update
        assert(Squirtle.parse("UPDATE table SET field = 1"))
    end

    def test_insert
        assert(Squirtle.parse("INSERT INTO employees (name, salary) VALUES ('kevin', 40000),('bob', 90000)"))
    end

    def test_delete
        assert(Squirtle.parse("DELETE FROM table WHERE id IN (1,2,3)"))
    end

    def test_select_join
        assert(Squirtle.parse("SELECT author.name, book.title FROM books AS book JOIN authors AS author ON book.author_id = author.id WHERE book.id = 123"))
    end

    def test_invalid_fails
        assert(!Squirtle.parse("SELECT uhh"))
    end

    def test_invalid_two
        assert(!Squirtle.parse("SELECT $ FROM 098 WHERE xyz = SELECT"))
    end

    def test_find
        ast = Squirtle.parse("SELECT * FROM some_table WHERE some_value = 'kevin'")
        assert(ast, "should have result")
        f = ast.find(:field)
        assert(f.count, 1)
        assert(f.first.sequence_name == :field)
    end

    def test_find_joins
        ast = Squirtle.parse("SELECT * FROM employees JOIN salaries ON salaries.employee_id = employees.id AND salaries.amount > 5000 JOIN cars AS car ON car.employee_id = employees.id")
        f = ast.find(:join)
        assert(f.count, 2)
        assert(f.all? {|t| t.sequence_name == :join})
    end

    def test_inspect_from_table
        ast = Squirtle.parse("SELECT name, gender FROM employees WHERE salary > 600000")
        i = Squirtle::Inspector.new(ast)
        table_name = i.from_table
        assert(table_name, "employees")
    end

    def test_inspect_select_fields
        ast = Squirtle.parse(SIMPLE_QUERY)
        i = Squirtle::Inspector.new(ast)
        assert(i.select_fields == ["name", "gender"])
    end

    def test_inspect_query_type
        ast = Squirtle.parse(SIMPLE_QUERY)
        i = Squirtle::Inspector.new(ast)
        assert(i.query_type == :select)
    end

    def test_inspect_where_criteria
        ast = Squirtle.parse(SIMPLE_QUERY)
        i = Squirtle::Inspector.new(ast)
        assert(!!i.where_has?("salary"))
    end

    def test_inspect_expr_op
        ast = Squirtle.parse(SIMPLE_QUERY)
        i = Squirtle::Inspector.new(ast)
        assert(i.where_has?("salary").rs == '60000')
        assert(i.where_has?("salary").op == :gt)
        assert(i.where_has?("car_color").op == :eq)
    end

    def test_inspector_join_table_list
        ast = Squirtle.parse("SELECT * 
            FROM employees 
            JOIN salaries 
                ON salaries.employee_id = employees.id AND salaries.amount > 5000 
            JOIN cars AS car ON car.employee_id = employees.id
        ")
        inspector = Squirtle::Inspector.new(ast)
        jt = inspector.join_tables
        assert(jt == ['salaries', 'cars'])
    end

    def test_magic_traversal
        ast = Squirtle.parse(SIMPLE_QUERY)
        assert(ast.get_child(:select) == ast.select)
    end
end