import stdlib.web.client

millis = Mutable.make({none})
function timepr(s) {
  now = Date.in_milliseconds(Date.now());
  prefix = match (millis.get()) {
   case {none}: ""
   case {some:ms}: Int.to_string(now - ms)
  };
  millis.set({some:now});
  println(prefix ^ " " ^ s)
}

type User.t = {
  int id,
  string name,
}

type watching = {
  int watcher_id,
  int watchee_id,
}
function watchee(w) { w.watchee_id }
function watcher(w) { w.watcher_id }

database test_watch {
  User.t /users[{id}]
  watching /watching[{watcher_id, watchee_id}]
}

function init_db() {
  users = [
    { id: 0, name:"ogunden" },
    { id: 1, name:"ogunden1" },
    { id: 2, name:"ogunden2" },
    { id: 3, name:"ogunden3" },
    { id: 4, name:"ogunden4" },
    { id: 5, name:"ogunden5" },
    { id: 6, name:"ogunden6" },
    { id: 7, name:"ogunden7" },
    { id: 8, name:"ogunden8" },
    { id: 9, name:"ogunden9" },
  ];
  list(watching) watchings = [
    { watcher_id: 0, watchee_id: 1 },
    { watcher_id: 0, watchee_id: 2 },
    { watcher_id: 0, watchee_id: 3 },
    { watcher_id: 0, watchee_id: 4 },
    { watcher_id: 0, watchee_id: 5 },
    { watcher_id: 0, watchee_id: 6 },
    { watcher_id: 0, watchee_id: 7 },
    { watcher_id: 0, watchee_id: 8 },
    { watcher_id: 0, watchee_id: 9 },
  ];
  function insert_user(u) {
    /test_watch/users[{id:u.id}] <- u
  };
  function insert_watching(w) {
    /test_watch/watching[w] <- w
  };
  List.iter(insert_user,users);
  List.iter(insert_watching,watchings);
}

function list_of_dbset(dbset) {
  Iter.to_list(DbSet.iterator(dbset))
}

module User {

  function get_current() {
    {id:0, name:"ogunden"}
  }

  function of_id(int id) {
    ?/test_watch/users[{~id}]
  }

  int -> list(User.t) function get_watching(int p_watcher_id) {
    ds =
      /test_watch/watching[watcher_id == p_watcher_id];
    ws = list_of_dbset(ds);
    watchees = List.map(watchee, ws);
    List.filter_map(of_id, watchees)
  }

  watching -> void function stop_watching(watching w) {
    Db.remove(@/test_watch/watching[w])
  }
}

module User_watchlist {

  function do_unwatch(watchee_id,_) {
    me = User.get_current();
    User.stop_watching({watcher_id:me.id,~watchee_id});
    Client.reload()
  }

  function do_nothing(_) {
    Client.reload()
  }

  function xhtml non_empty_watchlist(list(User.t) wl) {
    client function xhtml row(someone) {
      timepr("before xhtml");
      x = <tr>
        <td>
         {someone.name}
        </td>
        </tr>;
      timepr("row end");
      x
    } // function row
    <>
     <table class="table-striped table-fillout">
      <thead>
       <tr>
        <th colspan="2">name</th>
       </tr>
      </thead>
     <tbody>
      {Xhtml.createFragment(List.map(row, wl))}
      </tbody>
     </table>
    </>
  }

  function render_mewatching() {
    me = User.get_current();
    my_watchlist = User.get_watching(me.id);
    timepr("after get_mewatching");
    html =
      match (my_watchlist) {
        case []:
          <p> You're not watching anything yet. </p>
        case my_watchlist:
          non_empty_watchlist(my_watchlist)
      };
    timepr("after non_empty_watchlist");
    Dom.transform([#mewatching = html])
  }

  function xhtml page() {
   <>
    <div id="status"/>
    <a onclick={function(_) { init_db() }}>
      init db
    </a>
    <div onready={
      function(_) { render_mewatching() }}
    >
     <div class="section"> <div id="mewatching"/> </div>
    </div>
   </>
  }

}

Server.start(Server.http,
  {title:"test", page: User_watchlist.page}
)
