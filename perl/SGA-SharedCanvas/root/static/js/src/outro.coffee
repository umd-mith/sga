MITHGrid.defaults 'sga.component.modalForm',
  events:
    onAction: null

MITHGrid.defaults 'sga.application.top',
  dataStores:
    data:
      types:
        SectionLink: {}
        URLLink: {}
        Project: {}
        Library: {}
        Board: {}
        BoardRank: {}
        Page: {}
        PagePart: {}
      properties:
        board_ranks:
          valueType: 'item'
        pages:
          valueType: 'item'
        parent:
          valueType: 'item'
  dataViews:
    metroItems:
      dataStore: 'data'
      type: MITHGrid.Data.SubSet
      key: 'top',
      expressions: [ '!parent' ]
    metroTopItems:
      dataStore: 'data'
      type: MITHGrid.Data.SubSet
      key: 'top',
      expressions: [ '!parent' ]
  variables:
    MetroParent:
      is: 'rw'
      default: 'top'
    MetroMode:
      is: 'rw'
      default: 'list'
    Authenticated:
      is: 'rw'
      default: true
  presentations:
    list:
      type: sga.presentation.metro
      container: " .metro-hub"
      dataView: 'metroItems'
    nav:
      type: sga.presentation.metroNav
      container: " .metro-nav"
      dataView: 'metroTopItems'
  viewSetup: """
    <div class="navbar navbar-fixed-top">
     <div class="navbar-inner">
       <div class="container">
         <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
           <span class="icon-bar"></span>
           <span class="icon-bar"></span>
           <span class="icon-bar"></span>
         </a>
         <a class="brand" href="#" id="top-nav">Shared Canvas</a>
         <div class="nav-collapse">
          <ul class="nav pull-right" id="menu-settings" style="display: none;">
             <li class="dropdown">
               <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                 Account
                 <b class="caret"></b>
               </a>
               <ul class="dropdown-menu">
                 <li><a href="#" id="cmd-user"><i class="icon-user icon-white"></i> Profile</a></li>
                 <li><a href="#" id="cmd-cog"><i class="icon-cog icon-white"></i> Settings</a></li>
                 <li class="divider"></li>
                 <li><a href="#" id="cmd-off"><i class="icon-off icon-white"></i> Logout</a></li>
               </ul>
             </li>
          </ul>
           <ul class="nav">
             <li class="dropdown">
               <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                 <span id="section-header">Home</span>
                 <b class="caret"></b>
               </a>
              <ul class='dropdown-menu metro-nav'></ul>
             </li>
           </ul>
         </div>
       </div>
     </div>
    </div>
    <div class="row-fluid">
      <div class="span12">
        <ul class="breadcrumb metro-breadcrumb" style="display: none;">
        </ul>
      </div>
    </div>
    <div class="row-fluid">
      <div class="span12 metro-hub"></div>
    </div>
    <div style="clear: both;" class="row-fluid"></div>
    <div class="navbar navbar-fixed-bottom">
      <div class="navbar-inner">
        <div class="container">
          <ul class="nav pull-right" id="right-commands">
            <li class="divider-vertical"></li>
            <li id="li-trash" style="display: none;"><a href="#" id="cmd-trash"><i class="icon-trash icon-white"></i></a></li>
            <li id="li-remove" style="display: none;"><a href="#" id="cmd-remove"><i class="icon-remove icon-white"></i></a></li>
            <li id="li-edit" style="display: none;"><a href="#" id="cmd-edit"><i class="icon-edit icon-white"></i></a></li>
            <li id="li-plus" style="display: none;"><a href="#" id="cmd-plus"><i class="icon-plus icon-white"></i></a></li>
          </ul>
          <ul class="nav pull-left">
            <li id="li-home"><a href="#" id="cmd-home"><i class="icon-home icon-white"></i></a></li>
          </ul>
        </div>
      </div>
    </div>
  """
