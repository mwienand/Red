use DB::Pg;
use Red::Driver;
use Red::Driver::CommonSQL;
use Red::Statement;
unit class Red::Driver::Pg does Red::Driver::CommonSQL;

has Str $!user;
has Str $!password;
has Str $!host = "127.0.0.1";
has Int $!port = 5432;
has Str $!dbname;
has $!dbh = DB::Pg.new: conninfo => "{ "user=$_" with $!user } { "password=$_" with $!password } { "host=$_" with $!host } { "port=$_" with $!port } { "dbname=$_" with $!dbname }";

multi method translate(Red::Column $_, "column-auto-increment") { Empty }

multi method translate(Red::AST::Insert $_, $context?) {
    my @values = .values.grep({ .value.value.defined });
    "INSERT INTO { .into.^table }(\n{ @values>>.key.join(",\n").indent: 3 }\n)\nVALUES(\n{ @values>>.value.map(-> $val { self.translate: $val, "insert" }).join(",\n").indent: 3 }\n) RETURNING *", []
}

multi method translate(Red::AST::Value $_ where .type ~~ Bool, $context?) {
    .value ?? "'t'" !! "'f'"
}

class Statement does Red::Statement {
    has Str $.query;
    method stt-exec($stt, *@bind) {
        my $s = $stt.query($!query, |@bind);
        do if $s ~~ DB::Pg::Results {
            $s.hashes
        } else {
            []
        }.iterator
    }
    method stt-row($stt) { $stt.pull-one }
}

multi method prepare(Red::AST $query) {
    my ($sql, @bind) := self.translate: self.optimize: $query;
    do unless $*RED-DRY-RUN {
        my $stt = self.prepare: $sql;
        $stt.predefined-bind;
        $stt.binds = @bind;
        $stt
    }
}

multi method prepare(Str $query) {
    self.debug: $query;
    Statement.new: :driver(self), :statement($!dbh), :$query
}

multi method default-type-for(Red::Column $                                                 --> "varchar(255)")  {}
multi method default-type-for(Red::Column $ where { .attr.type ~~ Int and .auto-increment } --> "serial")        {}
multi method default-type-for(Red::Column $ where .attr.type ~~ one(Int, Bool)              --> "integer")       {}
multi method default-type-for(Red::Column $ where .attr.type ~~ Bool                        --> "boolean")       {}
