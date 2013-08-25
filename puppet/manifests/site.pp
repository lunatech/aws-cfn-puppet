node basenode {

  include cfn

  include ntp

}

node /^cc\-.*internal$/ inherits basenode {
}

node /^be\-.*internal$/ inherits basenode {
}

node /^fe\-.*internal$/ inherits basenode {
}
