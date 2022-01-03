/*
* Copyright (c) 2022 (https://github.com/phase1geo/Actioneer)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

public enum ConditionType {
  TEXT,
  DATE
}

public enum ActionConditionType {
  NAME,
  EXTENSION,
  FULLNAME,
  CREATE_DATE,
  MODIFY_DATE,
  MIME,
  CONTENT,
  NUM;

  public string to_string() {
    switch( this ) {
      case NAME        :  return( "name" );
      case EXTENSION   :  return( "extension" );
      case FULLNAME    :  return( "fullname" );
      case CREATE_DATE :  return( "creation-date" );
      case MODIFY_DATE :  return( "modification-date" );
      case MIME        :  return( "mime" );
      case CONTENT     :  return( "content" );
      default          :  assert_not_reached();
    }
  }

  public static ActionConditionType parse( string val ) {
    switch( val ) {
      case "name"              :  return( NAME );
      case "extension"         :  return( EXTENSION );
      case "fullname"          :  return( FULLNAME );
      case "creation-date"     :  return( CREATE_DATE );
      case "modification-date" :  return( MODIFY_DATE );
      case "mime"              :  return( MIME );
      case "content"           :  return( CONTENT );
      default                  :  assert_not_reached();
    }
  }

  public ConditionType condition_type() {
    switch( this ) {
      case NAME        :  return( ConditionType.TEXT );
      case EXTENSION   :  return( ConditionType.TEXT );
      case FULLNAME    :  return( ConditionType.TEXT );
      case CREATE_DATE :  return( ConditionType.DATE );
      case MODIFY_DATE :  return( ConditionType.DATE );
      case MIME        :  return( ConditionType.TEXT );
      case CONTENT     :  return( ConditionType.TEXT );
      default          :  assert_not_reached();
    }
  }

  private string? get_fullname( string pathname ) {
    return( Filename.display_basename( pathname ) );
  }

  private string? get_name( string pathname ) {
    var parts = get_fullname( pathname ).split( "." );
    return( string.joinv( ".", parts[0:parts.length - 2] ) );
  }

  private string? get_extension( string pathname ) {
    var parts = get_fullname( pathname ).split( "." );
    return( parts[parts.length - 1] );
  }

  private FileInfo get_file_info( string pathname ) {
    var file = File.new_for_path( pathname );
    return( file.query_info( "time::*", 0 ) );
  }

  private DateTime? get_create_date( string pathname ) {
    return( get_file_info( pathname ).get_creation_date_time() );
  }

  private DateTime? get_modify_date( string pathname ) {
    return( get_file_info( pathname ).get_modification_date_time() );
  }

  private string? get_mime( string pathname ) {
    // TBD
    return( "" );
  }

  private string? get_contents( string pathname ) {
    try {
      var contents = "";
      FileUtils.get_contents( pathname, out contents );
      return( contents );
    } catch( FileError e ) {
      return( null );
    }
  }

  public string text_from_pathname( string pathname ) {
    switch( this ) {
      case NAME      :  return( get_name( pathname ) );
      case EXTENSION :  return( get_extension( pathname ) );
      case FULLNAME  :  return( get_fullname( pathname ) );
      case MIME      :  return( get_mime( pathname ) );
      case CONTENT   :  return( get_contents( pathname ) );
      default        :  assert_not_reached();
    }
  }

  public DateTime date_from_pathname( string pathname ) {
    switch( this ) {
      case CREATE_DATE :  return( get_create_date( pathname ) );
      case MODIFY_DATE :  return( get_modify_date( pathname ) );
      default          :  assert_not_reached();
    }
  }

}

public class ActionCondition {

  public static const string xml_node = "condition";

  private ActionConditionType _type = ActionConditionType.NAME;
  private TextCondition?      _text = null;
  private DateCondition?      _date = null;

  public ActionConditionType type {
    get {
      return( _type );
    }
    set {
      if( _type != value ) {
        _type = value;
        switch( _type.condition_type() ) {
          case ConditionType.TEXT :
            _text = new TextCondition();
            _date = null;
            break;
          case ConditionType.DATE :
            _text = null;
            _date = new DateCondition();
            break;
        }
      }
    }
  }

  /* Default constructor */
  public ActionCondition() {}

  /* Returns true if the given pathname passes this condition check */
  public bool check( string pathname ) {
    switch( type.condition_type() ) {
      case ConditionType.TEXT :  return( _text.check( type.text_from_pathname( pathname ) ) );
      case ConditionType.DATE :  return( _date.check( type.date_from_pathname( pathname ) ) );
      default                 :  return( false );
    }
  }

  /* Saves this condition in XML format */
  public Xml.Node* save() {

    Xml.Node* node = new Xml.Node( null, xml_node );

    node->set_prop( "type", type.to_string() );

    switch( type.condition_type() ) {
      case ConditionType.TEXT :  _text.save( node );  break;
      case ConditionType.DATE :  _date.save( node );  break;
    }

    return( node );

  }

  /* Loads this condition from XML format */
  public void load( Xml.Node* node ) {

    var t = node->get_prop( "type" );
    if( t != null ) {
      type = ActionConditionType.parse( t );
    }

    switch( type.condition_type() ) {
      case ConditionType.TEXT :  _text.load( node );  break;
      case ConditionType.DATE :  _date.load( node );  break;
    }

  }

}
