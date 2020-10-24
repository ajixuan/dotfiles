28092020
  * to make the above date: date +%d%m%Y
  * to print unicode chars in vim: <ctrl>+v [UNICODE]
  * to verify software sig signed by gpg sometimes you need to import the
    public key
  * curl wttr.in for weather
  * ovens ovenate
  * to show cycles in terraform terraform graph | dot -Tsvg > graph.svg
    graphviz is a good tool for visualizing graphs
29092020
  * terraform stores modules in the directory where terraform command is
    executed under .terraform
  * terraform state contains all the objects that terraform cares about.
    Terraform will only synch with the cloud on objects specified in the state.
  * terraform import is what terraform refresh does
  * ./terraform state rm # this is a good way to manage your state if it
    becomes corrupted, just remember to reimport after
20102020
  * -I where to find header files during compilation (build)
    -L where to find .a and .so files during linking (build)
    LD_LIBRARY_PATH extra places to find .so libs during loading (run)
    -rpath (RUNPATH), a list of paths separated by ':' where to look for .so
    libs when executing the binary
