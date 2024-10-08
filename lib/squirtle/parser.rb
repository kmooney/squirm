module Squirtle::Parser

    @grammar = Squirtle::SQLGrammar.grammar

    def self.debug(str, element, tag, d)
        puts (0...d).map {"    "}.join + "#{tag.inspect} -> #{element.inspect} '#{str[0...20]}'"
    end

    def self.sdebug(str, element)
        printf "%-40s %s\n", element.inspect, str
    end

    def self.eval_element(str, element, sequence_name, d = 0)
        str = str.strip.downcase
        #debug(str,element, sequence_name, d)
        #sdebug(str, element)
        #puts (0...d).map{" "}.join + "i: " + element.class.to_s + " " + element.to_s
        case element
        when String
            if str.start_with?(element.downcase)
                rest = str[element.length..-1]
                return Squirtle::TerminalNode.new(nil), rest
            else
                return false, str
            end
        when Regexp
            if m = str.match(element)
                rest = str[m[0].length..-1]
                return Squirtle::TerminalNode.new(m[0]), rest 
            else
                return false, str
            end
        when Squirtle::Grammar::OneOf
            _m = nil
            node = element.options.find do |o| 
                _m, _str = eval_element(str, o, sequence_name, d)
                str = _str if _m
                _m
            end
            if !node.nil?
                return _m, str
            else 
                return false, str
            end
        when Squirtle::Grammar::Optional
            node, str = eval_sequence(str, element.options, :optional, d + 1)
            if node
                return node, str
            else
                return Squirtle::TerminalNode.new(nil), str
            end
        when Symbol
            return eval_sequence(str, @grammar[element], element, d + 1)
        end
    end

    def self.eval_sequence(str, sequence, sequence_name, d = 0)
        tree = Squirtle::Node.new(sequence_name, d)
        str = str.strip.downcase
        sequence.each do |element|
            r, str = eval_element(str, element, sequence_name, d) 
            if r
                if r.sequence_name == :optional
                    r.children.each {|n| tree.add_child(n)}
                elsif !r.defunct 
                    tree.add_child(r)
                end
            else
                return false, str
            end
        end
        return tree, str
    end

    def self.match(str, sequence_name = nil)
        str = str.strip.downcase
        sequence_name = :statement if sequence_name.nil?
        sequence = @grammar[sequence_name]
        e, str = eval_sequence(str, sequence, sequence_name)
        return e
    end

end