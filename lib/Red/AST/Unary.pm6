use Red::AST::Operator;
class Red::AST::Cast does Red::AST::Operator {
    has Str $.type;
    has     $.value;
    method op { "::{$!type}" };

    method should-set {
        $!value.should-set
    }

    method new($value, $type) {
        ::?CLASS.bless: :$value, :$type
    }

    method find-column-name {
        $!value.?find-column-name // Empty
    }

    method find-value {
        $!value.?find-value // Empty
    }

    method args { $!value }
}

class Red::AST::Not does Red::AST::Operator {
    has Str $.type;
    has     $.value;
    method op { "not" };

    method should-set(|) { }

    method should-validate {}

    method new($value) {
        ::?CLASS.bless: :$value
    }

    method args { $!value }
}
