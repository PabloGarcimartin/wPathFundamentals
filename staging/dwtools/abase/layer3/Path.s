( function _Path_s_() {

'use strict';

/**
  @module Tools/base/Path - Collection of routines to operate paths in the reliable and consistent way. Path leverages parsing, joining, extracting, normalizing, nativizing, resolving paths. Use the module to get uniform experience from playing with paths on different platforms.
*/

/**
 * @file Path.s.
 */

/*

qqq !!! take into account

let path = '/C:/some/path';
_.uri.normalize( path )

*/

if( typeof module !== 'undefined' )
{

  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    let toolsPath = '../../../dwtools/Base.s';
    let toolsExternal = 0;
    try
    {
      toolsPath = require.resolve( toolsPath );
    }
    catch( err )
    {
      toolsExternal = 1;
      require( 'wTools' );
    }
    if( !toolsExternal )
    require( toolsPath );
  }

  let _ = _global_.wTools;

}

//

let _global = _global_;
let _ = _global_.wTools;
let Self = _.path = _.path || Object.create( null );

// --
// internal
// --

function Init()
{

  _.assert( _.strIs( this._rootStr ) );
  _.assert( _.strIs( this._upStr ) );
  _.assert( _.strIs( this._hereStr ) );
  _.assert( _.strIs( this._downStr ) );

  if( !this._hereUpStr )
  this._hereUpStr = this._hereStr + this._upStr;
  if( !this._downUpStr )
  this._downUpStr = this._downStr + this._upStr;

  this._upEscapedStr = _.regexpEscape( this._upStr );
  this._butDownUpEscapedStr = '(?!' + _.regexpEscape( this._downStr ) + this._upEscapedStr + ')';
  this._delDownEscapedStr = this._butDownUpEscapedStr + '((?!' + this._upEscapedStr + ').)+' + this._upEscapedStr + _.regexpEscape( this._downStr ) + '(' + this._upEscapedStr + '|$)';
  this._delDownEscaped2Str = this._butDownUpEscapedStr + '((?!' + this._upEscapedStr + ').|)+' + this._upEscapedStr + _.regexpEscape( this._downStr ) + '(' + this._upEscapedStr + '|$)';
  this._delUpRegexp = new RegExp( this._upEscapedStr + '+$' );
  this._delHereRegexp = new RegExp( this._upEscapedStr + _.regexpEscape( this._hereStr ) + '(' + this._upEscapedStr + '|$)','' );
  this._delDownRegexp = new RegExp( this._upEscapedStr + this._delDownEscaped2Str,'' );
  this._delDownFirstRegexp = new RegExp( '^' + this._delDownEscapedStr,'' );
  this._delUpDupRegexp = /\/{2,}/g;

}

//

function CloneExtending( o )
{
  // debugger;
  _.assert( arguments.length === 1 );
  let result = Object.create( this )
  _.mapExtend( result, Fields, o );
  // let result = _.mapExtend( null, this, Fields, o );
  result.Init();
  return result;
}

//

/*
qqq : use routineVectorize_functor instead
*/

function _pathMultiplicator_functor( o )
{

  if( _.routineIs( o ) || _.strIs( o ) )
  o = { routine : o }

  _.routineOptions( _pathMultiplicator_functor,o );
  _.assert( _.routineIs( o.routine ) );
  _.assert( o.fieldNames === null || _.longIs( o.fieldNames ) )

  /* */

  let routine = o.routine;
  let fieldNames = o.fieldNames;

  function supplement( src, l )
  {
    if( !_.longIs( src ) )
    src = _.arrayFillTimes( [], l, src );
    _.assert( src.length === l, 'routine expects arrays with same length' );
    return src;
  }

  function inputMultiplicator( o )
  {
    let result = [];
    let l = 0;
    let onlyScalars = true;

    if( arguments.length > 1 )
    {
      let args = [].slice.call( arguments );

      for( let i = 0; i < args.length; i++ )
      {
        if( onlyScalars && _.longIs( args[ i ] ) )
        onlyScalars = false;

        l = Math.max( l, _.arrayAs( args[ i ] ).length );
      }

      for( let i = 0; i < args.length; i++ )
      args[ i ] = supplement( args[ i ], l );

      for( let i = 0; i < l; i++ )
      {
        let argsForCall = [];

        for( let j = 0; j < args.length; j++ )
        argsForCall.push( args[ j ][ i ] );

        let r = routine.apply( this, argsForCall );
        result.push( r )
      }
    }
    else
    {
      if( fieldNames === null || !_.objectIs( o ) )
      {
        if( _.longIs( o ) )
        {
          for( let i = 0; i < o.length; i++ )
          result.push( routine.call( this, o[ i ] ) );
        }
        else
        {
          result = routine.call( this, o );
        }

        return result;
      }

      let fields = [];

      for( let i = 0; i < fieldNames.length; i++ )
      {
        let field = o[ fieldNames[ i ] ];

        if( onlyScalars && _.longIs( field ) )
        onlyScalars = false;

        l = Math.max( l, _.arrayAs( field ).length );
        fields.push( field );
      }

      for( let i = 0; i < fields.length; i++ )
      fields[ i ] = supplement( fields[ i ], l );

      for( let i = 0; i < l; i++ )
      {
        let options = _.mapExtend( null, o );
        for( let j = 0; j < fieldNames.length; j++ )
        {
          let fieldName = fieldNames[ j ];
          options[ fieldName ] = fields[ j ][ i ];
        }

        result.push( routine.call( this, options ) );
      }
    }

    _.assert( result.length === l );

    if( onlyScalars )
    return result[ 0 ];

    return result;
  }

  return inputMultiplicator;
}

_pathMultiplicator_functor.defaults =
{
  routine : null,
  fieldNames : null
}

//

function _filterNoInnerArray( arr )
{
  return arr.every( ( e ) => !_.arrayIs( e ) );
}

//

function _filterOnlyPath( e,k,c )
{
  if( _.strIs( k ) )
  {
    if( _.strEnds( k,'Path' ) )
    return true;
    else
    return false
  }
  return this.is( e );
}

// --
// path tester
// --

function is( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  return _.strIs( path );
}

//

function are( paths )
{
  let self = this;
  _.assert( arguments.length === 1, 'expects single argument' );
  if( !_.arrayIs( paths ) )
  return false;
  return paths.every( ( path ) => self.is( path ) );
}

//

function like( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  if( this.is( path ) )
  return true;
  if( _.FileRecord )
  if( path instanceof _.FileRecord )
  return true;
  return false;
}

//

/**
 * Checks if string is correct possible for current OS path and represent file/directory that is safe for modification
 * (not hidden for example).
 * @param filePath
 * @returns {boolean}
 * @method isSafe
 * @memberof wTools
 */

function isSafe( filePath,concern )
{
  filePath = this.normalize( filePath );

  if( concern === undefined )
  concern = 1;

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.assert( _.numberIs( concern ) );

  if( concern >= 2 )
  if( /(^|\/)\.(?!$|\/|\.)/.test( filePath ) )
  return false;

  if( concern >= 1 )
  if( filePath.indexOf( '/' ) === 1 )
  if( filePath[ 0 ] === '/' )
  {
    throw _.err( 'not tested' );
    return false;
  }

  if( concern >= 3 )
  if( /(^|\/)node_modules($|\/)/.test( filePath ) )
  return false;

  if( concern >= 1 )
  {
    let isAbsolute = this.isAbsolute( filePath );
    if( isAbsolute )
    if( this.isAbsolute( filePath ) )
    {
      let level = _.strCount( filePath,this._upStr );
      if( this._upStr.indexOf( this._rootStr ) !== -1 )
      level -= 1;
      if( filePath.split( this._upStr )[ 1 ].length === 1 )
      level -= 1;
      if( level <= 0 )
      return false;
    }
  }

  // if( safe )
  // safe = filePath.length > 8 || ( filePath[ 0 ] !== '/' && filePath[ 1 ] !== ':' );

  return true;
}

//

function isNormalized( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ) );
  return this.normalize( path ) === path;
}

//

function isAbsolute( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ), 'expects string {-path-}, but got', _.strTypeOf( path ) );
  _.assert( path.indexOf( '\\' ) === -1,'expects normalized {-path-}, but got', path );
  return _.strBegins( path,this._upStr );
}

//

function isRelative( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ), 'expects string {-path-}, but got', _.strTypeOf( path ) );
  return !this.isAbsolute( path );
}

//

function isRoot( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ), 'expects string {-path-}, but got', _.strTypeOf( path ) );
  return path === this._rootStr;
}

//

function isRefined( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ), 'expects string {-path-}, but got', _.strTypeOf( path ) );

  if( !path.length )
  return false;

  if( path[ 1 ] === ':' && path[ 2 ] === '\\' )
  return false;

  let leftSlash = /\\/g;
  let doubleSlash = /\/\//g;

  if( leftSlash.test( path ) /* || doubleSlash.test( path ) */ )
  return false;

  /* check right "/" */
  if( path !== this._upStr && !_.strEnds( path,this._upStr + this._upStr ) && _.strEnds( path,this._upStr ) )
  return false;

  return true;
}

//

function isDotted( srcPath )
{
  return _.strBegins( srcPath,this._hereStr );
}

// --
// normalizer
// --

function refine( src )
{

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( src ) );

  if( !src.length )
  return this._hereStr;

  let result = src;

  if( result[ 1 ] === ':' && ( result[ 2 ] === '\\' || result[ 2 ] === '/' || result.length === 2 ) )
  result = '/' + result[ 0 ] + '/' + result.substring( 3 );

  result = result.replace( /\\/g,'/' );

  /* remove right "/" */

  if( result !== this._upStr && !_.strEnds( result, this._upStr + this._upStr ))
  result = _.strRemoveEnd( result,this._upStr );

  // if( result !== this._upStr )
  // result = result.replace( this._delUpRegexp, '' );

  return result;
}

//

let pathsRefine = _.routineVectorize_functor
({
  routine : refine,
  vectorizingArray : 1,
  vectorizingMap : 1,
});

let pathsOnlyRefine = _.routineVectorize_functor
({
  routine : refine,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
});

//

function _pathNormalize( o )
{
  if( !o.src.length )
  return '.';

  let result = o.src;
  let endsWithUpStr = o.src === this._upStr || _.strEnds( o.src,this._upStr );
  result = this.refine( o.src );
  let beginsWithHere = o.src === this._hereStr || _.strBegins( o.src,this._hereUpStr ) || _.strBegins( o.src, this._hereStr + '\\' );

  /* remove "." */

  if( result.indexOf( this._hereStr ) !== -1 )
  {
    while( this._delHereRegexp.test( result ) )
    result = result.replace( this._delHereRegexp,this._upStr );
  }

  if( _.strBegins( result,this._hereUpStr ) && !_.strBegins( result, this._hereUpStr + this._upStr ) )
  result = _.strRemoveBegin( result,this._hereUpStr );

  /* remove ".." */

  if( result.indexOf( this._downStr ) !== -1 )
  {
    while( this._delDownRegexp.test( result ) )
    result = result.replace( this._delDownRegexp,this._upStr );
  }

  /* remove first ".." */

  if( result.indexOf( this._downStr ) !== -1 )
  {
    while( this._delDownFirstRegexp.test( result ) )
    result = result.replace( this._delDownFirstRegexp,'' );
  }

  if( !o.tolerant )
  {
    /* remove right "/" */

    if( result !== this._upStr && !_.strEnds( result, this._upStr + this._upStr ) )
    result = _.strRemoveEnd( result,this._upStr );
  }
  else
  {
    /* remove "/" duplicates */

    result = result.replace( this._delUpDupRegexp, this._upStr );

    if( endsWithUpStr )
    result = _.strAppendOnce( result, this._upStr );
  }

  /* nothing left */

  if( !result.length )
  result = '.';

  /* get back left "." */

  if( beginsWithHere )
  result = this.dot( result );

  return result;
}

//

/**
 * Regularize a path by collapsing redundant delimeters and resolving '..' and '.' segments, so A//B, A/./B and
    A/foo/../B all become A/B. This string manipulation may change the meaning of a path that contains symbolic links.
    On Windows, it converts forward slashes to backward slashes. If the path is an empty string, method returns '.'
    representing the current working directory.
 * @example
   let path = '/foo/bar//baz1/baz2//some/..'
   path = wTools.normalize( path ); // /foo/bar/baz1/baz2
 * @param {string} src path for normalization
 * @returns {string}
 * @method normalize
 * @memberof wTools
 */

function normalize( src )
{
  _.assert( _.strIs( src ),'expects string' );

  let result = this._pathNormalize({ src : src, tolerant : false });

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( result.length > 0 );
  _.assert( result === this._upStr || _.strEnds( result,this._upStr + this._upStr ) ||  !_.strEnds( result,this._upStr ) );
  _.assert( result.lastIndexOf( this._upStr + this._hereStr + this._upStr ) === -1 );
  _.assert( !_.strEnds( result,this._upStr + this._hereStr ) );

  if( Config.debug )
  {
    let i = result.lastIndexOf( this._upStr + this._downStr + this._upStr );
    _.assert( i === -1 || !/\w/.test( result.substring( 0,i ) ) );
  }

  return result;
}

//

let pathsNormalize = _.routineVectorize_functor
({
  routine : normalize,
  vectorizingArray : 1,
  vectorizingMap : 1,
});

let pathsOnlyNormalize = _.routineVectorize_functor
({
  routine : normalize,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
});

//

function normalizeTolerant( src )
{
  _.assert( _.strIs( src ),'expects string' );

  let result = this._pathNormalize({ src : src, tolerant : true });

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( result.length > 0 );
  _.assert( result === this._upStr || _.strEnds( result,this._upStr ) || !_.strEnds( result,this._upStr + this._upStr ) );
  _.assert( result.lastIndexOf( this._upStr + this._hereStr + this._upStr ) === -1 );
  _.assert( !_.strEnds( result,this._upStr + this._hereStr ) );

  if( Config.debug )
  {
    _.assert( !this._delUpDupRegexp.test( result ) );
  }

  return result;
}

//

function dot( path )
{

  _.assert( !_.path.isAbsolute( path ) );
  _.assert( arguments.length === 1 );

  if( path !== this._hereStr && !_.strBegins( path,this._hereUpStr ) && path !== this._downStr && !_.strBegins( path,this._downUpStr ) )
  {
    _.assert( !_.strBegins( path,this._upStr ) );
    path = this._hereUpStr + path;
  }

  // _rootStr : '/',
  // _upStr : '/',
  // _hereStr : '.',
  // _downStr : '..',

  return path;
}

//

let pathsDot = _.routineVectorize_functor
({
  routine : dot,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyDot = _.routineVectorize_functor
({
  routine : dot,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

function undot( path )
{
  return _.strRemoveBegin( path, this._hereUpStr );
}

let pathsUndot = _.routineVectorize_functor
({
  routine : undot,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyUndot = _.routineVectorize_functor
({
  routine : undot,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

function trail( path )
{
  _.assert( _.path.is( path ) );
  _.assert( arguments.length === 1 );

  if( !_.strEnd( this._upStr ) )
  return path + this._upStr;

  return path;
}

//

let pathsTrail = _.routineVectorize_functor
({
  routine : trail,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyTrail = _.routineVectorize_functor
({
  routine : trail,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

function untrail( path )
{
  _.assert( _.path.is( path ) );
  _.assert( arguments.length === 1 );

  if( _.strEnd( this._upStr ) && path !== this._rootStr )
  return _.strRemoveEnd( path, this._upStr );

  return path;
}

let pathsUntrail = _.routineVectorize_functor
({
  routine : untrail,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyUntrail = _.routineVectorize_functor
({
  routine : untrail,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

function _pathNativizeWindows( filePath )
{
  let self = this;
  _.assert( _.strIs( filePath ) ) ;
  let result = filePath.replace( /\//g, '\\' );

  if( result[ 0 ] === '\\' )
  if( result.length === 2 || result[ 2 ] === ':' || result[ 2 ] === '\\' )
  result = result[ 1 ] + ':' + result.substring( 2 );

  return result;
}

//

function _pathNativizeUnix( filePath )
{
  let self = this;
  _.assert( _.strIs( filePath ) );
  return filePath;
}

//

let nativize;
if( _global.process && _global.process.platform === 'win32' )
nativize = _pathNativizeWindows;
else
nativize = _pathNativizeUnix;

// --
// path join
// --

/**
 * Joins filesystem paths fragments or urls fragment into one path/url. Uses '/' level delimeter.
 * @param {Object} o join o.
 * @param {String[]} p.paths - Array with paths to join.
 * @param {boolean} [o.reroot=false] If this parameter set to false (by default), method joins all elements in
 * `paths` array, starting from element that begins from '/' character, or '* :', where '*' is any drive name. If it
 * is set to true, method will join all elements in array. Result
 * @returns {string}
 * @private
 * @throws {Error} If missed arguments.
 * @throws {Error} If elements of `paths` are not strings
 * @throws {Error} If o has extra parameters.
 * @method _pathJoin_body
 * @memberof wTools
 */

function _pathJoin_body( o )
{
  let self = this;
  let result = null;
  let prepending = true;

  /* */

  _.assert( Object.keys( o ).length === 3 );
  _.assert( o.paths.length > 0 );
  _.assert( _.boolLike( o.reroot ) );

  /* */

  for( let a = o.paths.length-1 ; a >= 0 ; a-- )
  {
    let src = o.paths[ a ];
    _.sure( _.strIs( src ) || src === null, () => 'expects strings as path arguments, but #' + a + ' argument is ' + _.strTypeOf( src ) );
  }

  /* */

  for( let a = o.paths.length-1 ; a >= 0 ; a-- )
  {
    let src = o.paths[ a ];

    if( o.allowingNull )
    if( src === null )
    break;

    if( result === null )
    result = '';

    // _.assert( _.strIs( src ), () => 'expects strings as path arguments, but #' + a + ' argument is ' + _.strTypeOf( src ) );

    prepending = prepend( src );
    if( prepending === false )
    break;

  }

  /* */

  if( result === '' )
  return '.';

  return result;

  /* */

  function prepend( src )
  {

    if( src )
    src = self.refine( src );

    if( !src )
    return prepending;

    let doPrepend = prepending;

    if( doPrepend )
    {

      src = src.replace( /\\/g, '/' );

      if( result && src[ src.length-1 ] === '/' && !_.strEnds( src, '//' ) )
      if( src.length > 1 || result[ 0 ] === '/' )
      src = src.substr( 0,src.length-1 );

      if( src && src[ src.length-1 ] !== '/' && result && result[ 0 ] !== '/' )
      result = '/' + result;

      result = src + result;

    }

    if( !o.reroot )
    {
      if( src[ 0 ] === '/' )
      return false;
    }

    return prepending;
  }

}

_pathJoin_body.defaults =
{
  paths : null,
  reroot : 0,
  allowingNull : 1,
}

//

function _pathsJoin_body( o )
{
  let isArray = false;
  let length = 0;

  /* */

  for( let p = 0 ; p < o.paths.length ; p++ )
  {
    let path = o.paths[ p ];
    if( _.arrayIs( path ) )
    {
      _.assert( _filterNoInnerArray( path ), 'Array must not have inner array( s ).' )

      if( isArray )
      _.assert( path.length === length, 'Arrays must have same length.' );
      else
      {
        length = Math.max( path.length,length );
        isArray = true;
      }
    }
    else
    {
      length = Math.max( 1,length );
    }
  }

  if( isArray === false )
  return this._pathJoin_body( o );

  /* */

  let paths = o.paths;
  function argsFor( i )
  {
    let res = [];
    for( let p = 0 ; p < paths.length ; p++ )
    {
      let path = paths[ p ];
      if( _.arrayIs( path ) )
      res[ p ] = path[ i ];
      else
      res[ p ] = path;
    }
    return res;
  }

  /* */

  let result = new Array( length );
  for( let i = 0 ; i < length ; i++ )
  {
    o.paths = argsFor( i );
    result[ i ] = this._pathJoin_body( o );
  }

  return result;
}

//

/**
 * Method joins all `paths` together, beginning from string that starts with '/', and normalize the resulting path.
 * @example
 * let res = wTools.join( '/foo', 'bar', 'baz', '.');
 * // '/foo/bar/baz'
 * @param {...string} paths path strings
 * @returns {string} Result path is the concatenation of all `paths` with '/' directory delimeter.
 * @throws {Error} If one of passed arguments is not string
 * @method join
 * @memberof wTools
 */

function join()
{

  let result = this._pathJoin_body
  ({
    paths : arguments,
    reroot : 0,
    allowingNull : 1,
  });

  return result;
}

//

let pathsJoin = _pathMultiplicator_functor
({
  routine : join
});

//

/**
 * Method joins all `paths` strings together.
 * @example
 * let res = wTools.reroot( '/foo', '/bar/', 'baz', '.');
 * // '/foo/bar/baz/.'
 * @param {...string} paths path strings
 * @returns {string} Result path is the concatenation of all `paths` with '/' directory delimeter.
 * @throws {Error} If one of passed arguments is not string
 * @method reroot
 * @memberof wTools
 */

function reroot()
{
  let result = this._pathJoin_body
  ({
    paths : arguments,
    reroot : 1,
    allowingNull : 1,
  });
  return result;
}

//

function pathsReroot()
{
  let result = this._pathsJoin_body
  ({
    paths : arguments,
    reroot : 1,
    allowingNull : 1,
  });

  return result;
}

//

function pathsOnlyReroot()
{
  let result = arguments[ 0 ];
  let length = 0;
  let firstArr = true;

  for( let i = 1; i <= arguments.length - 1; i++ )
  {
    if( this.is( arguments[ i ] ) )
    result = this.reroot( result, arguments[ i ] );

    if( _.arrayIs( arguments[ i ]  ) )
    {
      let arr = arguments[ i ];

      if( !firstArr )
      _.assert( length === arr.length );

      for( let j = 0; j < arr.length; j++ )
      {
        if( _.arrayIs( arr[ j ] ) )
        throw _.err( 'Inner arrays are not allowed.' );

        if( this.is( arr[ j ] ) )
        result = this.reroot( result, arr[ j ] );
      }

      length = arr.length;
      firstArr = false;
    }
  }

  return result;
}

//

/**
 * Method resolves a sequence of paths or path segments into an absolute path.
 * The given sequence of paths is processed from right to left, with each subsequent path prepended until an absolute
 * path is constructed. If after processing all given path segments an absolute path has not yet been generated,
 * the current working directory is used.
 * @example
 * let absPath = wTools.resolve('work/wFiles'); // '/home/user/work/wFiles';
 * @param [...string] paths A sequence of paths or path segments
 * @returns {string}
 * @method resolve
 * @memberof wTools
 */

function resolve()
{
  let path;

  _.assert( arguments.length > 0 );

  path = this.join.apply( this, arguments );

  if( path === null )
  path = this.current();
  else if( !this.isAbsolute( path ) )
  path = this.join( this.current(), path );

  path = this.normalize( path );

  _.assert( path.length > 0 );

  return path;
}

//

function _pathsResolveAct( join,paths )
{

  _.assert( paths.length > 0 );

  paths = join.apply( this, paths );
  paths = _.arrayAs( paths );

  for( let i = 0; i < paths.length; i++ )
  {
    if( paths[ i ][ 0 ] !== this._upStr )
    paths[ i ] = this.join( this.current(),paths[ i ] );
  }

  paths = this.pathsNormalize( paths );

  _.assert( paths.length > 0 );

  return paths;
}

//

let pathsResolve = _pathMultiplicator_functor
({
  routine : resolve
});

//

function pathsOnlyResolve()
{
  debugger;
  throw _.err( 'not tested' );
  let result = this._pathsResolveAct( pathsOnlyJoin, arguments );
  return result;
}

// --
// path cut off
// --

/**
 * Returns the directory name of `path`.
 * @example
 * let path = '/foo/bar/baz/text.txt'
 * wTools.dir( path ); // '/foo/bar/baz'
 * @param {string} path path string
 * @returns {string}
 * @throws {Error} If argument is not string
 * @method dir
 * @memberof wTools
 */

function dir( path )
{

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIsNotEmpty( path ) , 'dir','expects not empty string ( path )' );

  // if( path.length > 1 )
  // if( path[ path.length-1 ] === '/' && path[ path.length-2 ] !== '/' )
  // path = path.substr( 0,path.length-1 )

  path = this.refine( path );

  if( path === this._rootStr )
  {
    return path + this._downStr;
  }

  if( _.strEnds( path,this._upStr + this._downStr ) || path === this._downStr )
  {
    return path + this._upStr + this._downStr;
  }

  let i = path.lastIndexOf( this._upStr );

  if( i === -1 )
  {

    if( path === this._hereStr )
    return this._downStr;
    else
    return this._hereStr;

  }

  if( path[ i - 1 ] === '/' )
  return path;

  let result = path.substr( 0,i );

  // _.assert( result.length > 0 );

  if( result === '' )
  result = this._rootStr;

  return result;
}

//

function _pathSplit( path )
{
  return path.split( this._upStr );
}

//

function split( path )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ) )
  let result = this._pathSplit( this.refine( path ) );
  return result;
}

//

let pathsDir = _.routineVectorize_functor
({
  routine : dir,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

let pathsOnlyDir = _.routineVectorize_functor
({
  routine : dir,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

/**
 * Returns dirname + filename without extension
 * @example
 * _.path.prefixGet( '/foo/bar/baz.ext' ); // '/foo/bar/baz'
 * @param {string} path Path string
 * @returns {string}
 * @throws {Error} If passed argument is not string.
 * @method prefixGet
 * @memberof wTools
 */

function prefixGet( path )
{

  if( !_.strIs( path ) )
  throw _.err( 'prefixGet :','expects strings as path' );

  let n = path.lastIndexOf( '/' );
  if( n === -1 ) n = 0;

  let parts = [ path.substr( 0,n ),path.substr( n ) ];

  n = parts[ 1 ].indexOf( '.' );
  if( n === -1 )
  n = parts[ 1 ].length;

  let result = parts[ 0 ] + parts[ 1 ].substr( 0, n );

  return result;
}

//

let pathsPrefixesGet = _.routineVectorize_functor
({
  routine : prefixGet,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyPrefixesGet = _.routineVectorize_functor
({
  routine : prefixGet,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

/**
 * Returns path name (file name).
 * @example
 * wTools.name( '/foo/bar/baz.asdf' ); // 'baz'
 * @param {string|object} path|o Path string, or options
 * @param {boolean} o.withExtension if this parameter set to true method return name with extension.
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @method name
 * @memberof wTools
 */

function name( o )
{

  if( _.strIs( o ) )
  o = { path : o };

  _.assert( arguments.length === 1, 'expects single argument' );
  _.routineOptions( name,o );
  _.assert( _.strIs( o.path ), 'expects strings {-o.path-}' );

  let i = o.path.lastIndexOf( '/' );
  if( i !== -1 )
  o.path = o.path.substr( i+1 );

  if( !o.withExtension )
  {
    let i = o.path.lastIndexOf( '.' );
    if( i !== -1 ) o.path = o.path.substr( 0,i );
  }

  return o.path;
}

name.defaults =
{
  path : null,
  withExtension : 0,
}

//

function fullName( path )
{

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ), 'expects strings {-path-}' );

  let i = path.lastIndexOf( '/' );
  if( i !== -1 )
  path = path.substr( i+1 );

  return path;
}

//

let pathsName = _.routineVectorize_functor
({
  routine : name,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyName = _.routineVectorize_functor
({
  routine : name,
  vectorizingArray : 1,
  vectorizingMap : 1,
  fieldFilter : function( e )
  {
    let path = _.objectIs( e ) ? e.path : e;
    return this.is( path );
  }
})

//

/**
 * Return path without extension.
 * @example
 * wTools.withoutExt( '/foo/bar/baz.txt' ); // '/foo/bar/baz'
 * @param {string} path String path
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @method withoutExt
 * @memberof wTools
 */

function withoutExt( path )
{

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ) );

  let name = _.strIsolateEndOrNone( path,'/' )[ 2 ] || path;

  let i = name.lastIndexOf( '.' );
  if( i === -1 || i === 0 )
  return path;

  let halfs = _.strIsolateEndOrNone( path,'.' );
  return halfs[ 0 ];
}

//

let pathsWithoutExt = _.routineVectorize_functor
({
  routine : withoutExt,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyWithoutExt = _.routineVectorize_functor
({
  routine : withoutExt,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

/**
 * Replaces existing path extension on passed in `ext` parameter. If path has no extension, adds passed extension
    to path.
 * @example
 * wTools.changeExt( '/foo/bar/baz.txt', 'text' ); // '/foo/bar/baz.text'
 * @param {string} path Path string
 * @param {string} ext
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @method changeExt
 * @memberof wTools
 */

// qqq : extend tests

function changeExt( path,ext )
{

  if( arguments.length === 2 )
  {
    _.assert( _.strIs( ext ) );
  }
  else if( arguments.length === 3 )
  {
    let sub = arguments[ 1 ];
    let ext = arguments[ 2 ];

    _.assert( _.strIs( sub ) );
    _.assert( _.strIs( ext ) );

    let cext = this.ext( path );

    if( cext !== sub )
    return path;
  }
  else _.assert( 'Expects 2 or 3 arguments' );

  if( ext === '' )
  return this.withoutExt( path );
  else
  return this.withoutExt( path ) + '.' + ext;

}

//

function _pathsChangeExt( src )
{
  _.assert( _.longIs( src ) );
  _.assert( src.length === 2 );

  return changeExt.apply( this, src );
}

let pathsChangeExt = _.routineVectorize_functor
({
  routine : _pathsChangeExt,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

let pathsOnlyChangeExt = _.routineVectorize_functor
({
  routine : _pathsChangeExt,
  vectorizingArray : 1,
  vectorizingMap : 1,
  fieldFilter : function( e )
  {
    return this.is( e[ 0 ] )
  }
})

//

/**
 * Returns file extension of passed `path` string.
 * If there is no '.' in the last portion of the path returns an empty string.
 * @example
 * _.path.ext( '/foo/bar/baz.ext' ); // 'ext'
 * @param {string} path path string
 * @returns {string} file extension
 * @throws {Error} If passed argument is not string.
 * @method ext
 * @memberof wTools
 */

function ext( path )
{

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ), 'expects string {-path-}, but got', _.strTypeOf( path ) );

  let index = path.lastIndexOf( '/' );
  if( index >= 0 )
  path = path.substr( index+1,path.length-index-1  );

  index = path.lastIndexOf( '.' );
  if( index === -1 || index === 0 )
  return '';

  index += 1;

  return path.substr( index,path.length-index ).toLowerCase();
}

//

let pathsExt = _.routineVectorize_functor
({
  routine : ext,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

let pathsOnlyExt = _.routineVectorize_functor
({
  routine : ext,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

/*
qqq : not covered by tests
*/

function exts( path )
{

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( path ), 'expects string {-path-}, but got', _.strTypeOf( path ) );

  path = this.name({ path : path, withExtension : 1 });

  let exts = path.split( '.' );
  exts.splice( 0,1 );
  exts = _.entityFilter( exts , ( e ) => !e ? undefined : e.toLowerCase() );

  return exts;
}

// --
// path transformer
// --

function current()
{
  _.assert( arguments.length === 0 );
  return this._upStr;
}

//

function from( src )
{

  _.assert( arguments.length === 1, 'expects single argument' );

  if( _.strIs( src ) )
  return src;
  else
  _.assert( 0, 'unexpected type of argument : ' + _.strTypeOf( src ) );

}

let pathsFrom = _.routineVectorize_functor
({
  routine : from,
  vectorizingArray : 1,
  vectorizingMap : 1,
});

//

function _relative( o )
{
  let self = this;
  let result = '';
  let relative = this.from( o.relative );
  let path = this.from( o.path );

  _.assert( _.strIs( relative ),'relative expects string {-relative-}, but got',_.strTypeOf( relative ) );
  _.assert( _.strIs( path ) || _.arrayIs( path ) );

  if( !o.resolving )
  {
    relative = this.normalize( relative );
    path = this.normalize( path );

    let relativeIsAbsolute = this.isAbsolute( relative );
    let isAbsoulute = this.isAbsolute( path );

    _.assert( relativeIsAbsolute && isAbsoulute || !relativeIsAbsolute && !isAbsoulute, 'Resolving is disabled, paths must be both absolute or relative.' );
  }
  else
  {
    relative = this.resolve( relative );
    path = this.resolve( path );

    _.assert( this.isAbsolute( relative ) );
    _.assert( this.isAbsolute( path ) );
  }

  _.assert( relative.length > 0 );
  _.assert( path.length > 0 );

  /* */

  let common = _.strCommonLeft( relative,path );

  function goodEnd( s )
  {
    return s.length === common.length || s.substring( common.length,common.length + self._upStr.length ) === self._upStr;
  }

  while( common.length > 1 )
  {
    if( !goodEnd( relative ) || !goodEnd( path ) )
    common = common.substring( 0,common.length-1 );
    else break;
  }

  /* */

  if( common === relative )
  {
    if( path === common )
    {
      result = '.';
    }
    else
    {
      result = _.strRemoveBegin( path, common );
      if( !_.strBegins( result,this._upStr+this._upStr ) && common !== this._upStr )
      result = _.strRemoveBegin( result,this._upStr );
    }
  }
  else
  {
    relative = _.strRemoveBegin( relative,common );
    path = _.strRemoveBegin( path,common );
    let count = _.strCount( relative,this._upStr );
    if( common === this._upStr )
    count += 1;

    if( !_.strBegins( path,this._upStr+this._upStr ) && common !== this._upStr )
    path = _.strRemoveBegin( path,this._upStr );

    result = _.strDup( this._downUpStr,count ) + path;

    if( _.strEnds( result,this._upStr ) )
    _.assert( result.length > this._upStr.length );
    result = _.strRemoveEnd( result,this._upStr );
  }

  if( _.strBegins( result,this._upStr + this._upStr ) )
  result = this._hereStr + result;
  else
  result = _.strRemoveBegin( result,this._upStr );

  _.assert( result.length > 0 );
  _.assert( !_.strEnds( result,this._upStr ) );
  _.assert( result.lastIndexOf( this._upStr + this._hereStr + this._upStr ) === -1 );
  _.assert( !_.strEnds( result,this._upStr + this._hereStr ) );

  if( Config.debug )
  {
    let i = result.lastIndexOf( this._upStr + this._downStr + this._upStr );
    _.assert( i === -1 || !/\w/.test( result.substring( 0,i ) ) );
  }

  if( !o.dotted )
  if( result === '.' )
  result = '';

  return result;
}

_relative.defaults =
{
  relative : null,
  path : null,
  resolving : 0,
  dotted : 1,
}

//

/**
 * Returns a relative path to `path` from an `relative` path. This is a path computation : the filesystem is not
   accessed to confirm the existence or nature of path or start. As second argument method can accept array of paths,
   in this case method returns array of appropriate relative paths. If `relative` and `path` each resolve to the same
   path method returns '.'.
 * @example
 * let from = '/foo/bar/baz',
   pathsTo =
   [
     '/foo/bar',
     '/foo/bar/baz/dir1',
   ],
   relatives = wTools.relative( from, pathsTo ); //  [ '..', 'dir1' ]
 * @param {string|wFileRecord} relative start path
 * @param {string|string[]} path path to.
 * @returns {string|string[]}
 * @method relative
 * @memberof wTools
 */

function relative( o )
{

  if( arguments[ 1 ] !== undefined )
  {
    o = { relative : arguments[ 0 ], path : arguments[ 1 ] }
  }

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.routineOptions( relative, o );

  let relativePath = this.from( o.relative );
  let path = this.from( o.path );

  return this._relative( o );
}

relative.defaults = Object.create( _relative.defaults );

//

function relativeUndoted( o )
{

  if( arguments[ 1 ] !== undefined )
  {
    o = { relative : arguments[ 0 ], path : arguments[ 1 ] }
  }

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.routineOptions( relativeUndoted, o );

  let relativePath = this.from( o.relative );
  let path = this.from( o.path );

  return this._relative( o );
}

relativeUndoted.defaults = Object.create( _relative.defaults );
relativeUndoted.defaults.dotted = 0;

//

function _pathsRelative( o )
{
  _.assert( _.objectIs( o ) || _.longIs( o ) );
  let args = _.arrayAs( o );

  return relative.apply( this, args );
}

let pathsRelative = _pathMultiplicator_functor
({
  routine : relative,
  fieldNames : [ 'relative', 'path' ]
})

function _filterForPathRelative( e )
{
  let paths = [];

  if( _.arrayIs( e ) )
  _.arrayAppendArrays( paths, e );

  if( _.objectIs( e ) )
  _.arrayAppendArrays( paths, [ e.relative, e.path ] );

  if( !paths.length )
  return false;

  return paths.every( ( path ) => this.is( path ) );
}

let pathsOnlyRelative = _.routineVectorize_functor
({
  routine : _pathsRelative,
  fieldFilter : _filterForPathRelative,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

function _common( src1, src2 )
{
  let self = this;

  _.assert( arguments.length === 2, 'expects exactly two arguments' );
  _.assert( _.strIs( src1 ) && _.strIs( src2 ) );

  let split = function( src )
  {
    // debugger;
    return _.strSplitFast( { src : src, delimeter : [ '/' ], preservingDelimeters : 1, preservingEmpty : 1 } );
  }

  // let fill = function( value, times )
  // {
  //   return _.arrayFillTimes( result : [], value : value, times : times } );
  // }

  function getCommon()
  {
    let length = Math.min( first.splitted.length, second.splitted.length );
    for( let i = 0; i < length; i++ )
    {
      if( first.splitted[ i ] === second.splitted[ i ] )
      {
        if( first.splitted[ i ] === self._upStr && first.splitted[ i + 1 ] === self._upStr )
        break;
        else
        result.push( first.splitted[ i ] );
      }
      else
      break;
    }
  }

  function parsePath( path )
  {
    let result =
    {
      isRelativeDown : false,
      isRelativeHereThen : false,
      isRelativeHere : false,
      levelsDown : 0
    };

    result.normalized = self.normalize( path );
    result.splitted = split( result.normalized );
    result.isAbsolute = self.isAbsolute( result.normalized );
    result.isRelative = !result.isAbsolute;

    if( result.isRelative )
    if( result.splitted[ 0 ] === self._downStr )
    {
      result.levelsDown = _.arrayCount( result.splitted, self._downStr );
      let substr = _.arrayFillTimes( [], result.levelsDown, self._downStr ).join( '/' );
      let withoutLevels = _.strRemoveBegin( result.normalized, substr );
      result.splitted = split( withoutLevels );
      result.isRelativeDown = true;
    }
    else if( result.splitted[ 0 ] === '.' )
    {
      result.splitted = result.splitted.splice( 2 );
      result.isRelativeHereThen = true;
    }
    else
    result.isRelativeHere = true;

    return result;
  }

  let result = [];
  let first = parsePath( src1 );
  let second = parsePath( src2 );

  let needToSwap = first.isRelative && second.isAbsolute;

  if( needToSwap )
  {
    let tmp = second;
    second = first;
    first = tmp;
  }

  let bothAbsolute = first.isAbsolute && second.isAbsolute;
  let bothRelative = first.isRelative && second.isRelative;
  let absoluteAndRelative = first.isAbsolute && second.isRelative;

  if( absoluteAndRelative )
  {
    if( first.splitted.length > 3 || first.splitted[ 0 ] !== '' || first.splitted[ 2 ] !== '' || first.splitted[ 1 ] !== '/' )
    {
      debugger;
      throw _.err( 'Incompatible paths.' );
    }
    else
    return '/';
  }

  if( bothAbsolute )
  {
    getCommon();

    result = result.join('');

    if( !result.length )
    result = '/';
  }

  if( bothRelative )
  {
    // console.log(  first.splitted, second.splitted );

    if( first.levelsDown === second.levelsDown )
    getCommon();

    result = result.join('');

    let levelsDown = Math.max( first.levelsDown, second.levelsDown );

    if( levelsDown > 0 )
    {
      let prefix = _.arrayFillTimes( [], levelsDown, self._downStr );
      prefix = prefix.join( '/' );
      result = prefix + result;
    }

    if( !result.length )
    {
      if( first.isRelativeHereThen && second.isRelativeHereThen )
      result = self._hereStr;
      else
      result = '.';
    }
  }

  // if( result.length > 1 )
  // if( _.strEnds( result, '/' ) )
  // result = result.slice( 0, -1 );

  return result;
}

//

function common( paths )
{

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.arrayIs( paths ) );

  paths = paths.slice();

  paths.sort( function( a, b )
  {
    return b.length - a.length;
  });

  let result = paths.pop();

  for( let i = 0, len = paths.length; i < len; i++ )
  result = this._common( paths[ i ], result );

  return result;
}

//

function _pathsCommon( o )
{
  let isArray = false;
  let length = 0;

  _.assertRoutineOptions( _pathsCommon, o );

  /* */

  for( let p = 0 ; p < o.paths.length ; p++ )
  {
    let path = o.paths[ p ];
    if( _.arrayIs( path ) )
    {
      _.assert( _filterNoInnerArray( path ), 'Array must not have inner array( s ).' )

      if( isArray )
      _.assert( path.length === length, 'Arrays must have same length.' );
      else
      {
        length = Math.max( path.length,length );
        isArray = true;
      }
    }
    else
    {
      length = Math.max( 1,length );
    }
  }

  if( isArray === false )
  return this.common( o.paths );

  /* */

  let paths = o.paths;
  function argsFor( i )
  {
    let res = [];
    for( let p = 0 ; p < paths.length ; p++ )
    {
      let path = paths[ p ];
      if( _.arrayIs( path ) )
      res[ p ] = path[ i ];
      else
      res[ p ] = path;
    }
    return res;
  }

  /* */

  // let result = _.entityMake( o.paths );
  let result = new Array( length );
  for( let i = 0 ; i < length ; i++ )
  {
    o.paths = argsFor( i );
    result[ i ] = this.common( o.paths );
  }

  return result;
}

_pathsCommon.defaults =
{
  paths : null,
}

//

function pathsCommon( paths )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.arrayIs( paths ) );

  paths = paths.slice();

  let result = this._pathsCommon
  ({
    paths : paths
  })

  return result;
}

//

let pathsOnlyCommon = _.routineVectorize_functor
({
  routine : common,
  fieldFilter : _filterOnlyPath,
  vectorizingArray : 1,
  vectorizingMap : 1,
})

//

function rebase( filePath, oldPath, newPath )
{

  _.assert( arguments.length === 3, 'expects exactly three argument' );

  filePath = this.normalize( filePath );
  if( oldPath )
  oldPath = this.normalize( oldPath );
  newPath = this.normalize( newPath );

  if( oldPath )
  {
    let commonPath = this.common([ filePath,oldPath ]);
    filePath = _.strRemoveBegin( filePath,commonPath );
  }

  filePath = this.reroot( newPath,filePath )

  return filePath;
}

//
//
// function relate( filePath, oldPath, newPath )
// {
//
//   _.assert( arguments.length === 3, 'expects exactly three argument' );
//   _.assert( _.strIs( filePath ) );
//   _.assert( _.strIs( oldPath ) );
//   _.assert( _.strIs( newPath ) );
//
//   let filePath1 = this.join( oldPath, filePath );
//   let filePath2 = this.relative( oldPath, filePath1 );
//
//   let prefix1 = this.relative( newPath, oldPath );
//   if( prefix1 === '.' )
//   prefix1 = '';
//
//   filePath = this.join( prefix1, filePath2 );
//   return filePath;
// }
//
// //
//
// function pathsRelate( filePath, oldPath, newPath )
// {
//   let length;
//
//   let multiplied = _.multipleAll([ filePath, oldPath, newPath ]);
//
//   filePath = multiplied[ 0 ];
//   oldPath = multiplied[ 1 ];
//   newPath = multiplied[ 2 ];
//
//   _.assert( arguments.length === 3, 'expects exactly three argument' );
//
//   if( _.arrayIs( filePath ) )
//   {
//     let result = [];
//     for( let f = 0 ; f < filePath.length ; f++ )
//     result[ f ] = this.relate( filePath[ f ], oldPath[ f ], newPath[ f ] );
//     return result;
//   }
//
//   return this.relate( filePath, oldPath, newPath );
// }

// --
// glob
// --

/*
(\*\*)| -- **
([?*])| -- ?*
(\[[!^]?.*\])| -- [!^]
([+!?*@]\(.*\))| -- @+!?*()
(\{.*\}) -- {}
(\(.*\)) -- ()
*/

// let transformation1 =
// [
//   [ /\[(.+?)\]/g, handleSquareBrackets ], /* square brackets */
//   [ /\{(.*)\}/g, handleCurlyBrackets ], /* curly brackets */
// ]
//
// let transformation2 =
// [
//   [ /\.\./g, '\\.\\.' ], /* double dot */
//   [ /\./g, '\\.' ], /* dot */
//   [ /([!?*@+]*)\((.*?(?:\|(.*?))*)\)/g, hanleParentheses ], /* parentheses */
//   [ /\/\*\*/g, '(?:\/.*)?', ], /* slash + double asterix */
//   [ /\*\*/g, '.*', ], /* double asterix */
//   [ /(\*)/g, '[^\/]*' ], /* single asterix */
//   [ /(\?)/g, '.', ], /* question mark */
// ]

// let _pathIsGlobRegexp = /(\*\*)|([?*])|(\[[!^]?.*\])|([+!?*@]?)|\{.*\}|(\(.*\))/;

let _pathIsGlobRegexpStr = '';
_pathIsGlobRegexpStr += '(?:[?*]+)'; /* asterix, question mark */
_pathIsGlobRegexpStr += '|(?:([!?*@+]*)\\((.*?(?:\\|(.*?))*)\\))'; /* parentheses */
_pathIsGlobRegexpStr += '|(?:\\[(.+?)\\])'; /* square brackets */
_pathIsGlobRegexpStr += '|(?:\\{(.*)\\})'; /* curly brackets */

let _pathIsGlobRegexp = new RegExp( _pathIsGlobRegexpStr );
function isGlob( src )
{
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( src ) );

  /* let regexp = /(\*\*)|([!?*])|(\[.*\])|(\(.*\))|\{.*\}+(?![^[]*\])/g; */

  return _pathIsGlobRegexp.test( src );
}

//

function fromGlob( glob )
{
  let result;

  _.assert( _.strIs( glob ) );
  _.assert( arguments.length === 1, 'expects single argument' );

  let i = glob.search( /[^\\\/]*?(\*\*|\?|\*|\[.*\]|\{.*\}+(?![^[]*\]))[^\\\/]*/ );
  if( i === -1 )
  result = glob;
  else
  result = glob.substr( 0,i );

  /* replace urlNormalize by detrail */
  result = _.uri.normalize( result );

  // if( !result && _.path.realMainDir )
  // debugger;
  // if( !result && _.path.realMainDir )
  // result = _.path.realMainDir();

  return result;
}

//

/**
 * Turn a *-wildcard style _glob into a regular expression
 * @example
 * let _glob = '* /www/*.js';
 * wTools.globRegexpsForTerminalSimple( _glob );
 * // /^.\/[^\/]*\/www\/[^\/]*\.js$/m
 * @param {String} _glob *-wildcard style _glob
 * @returns {RegExp} RegExp that represent passed _glob
 * @throw {Error} If missed argument, or got more than one argumet
 * @throw {Error} If _glob is not string
 * @function globRegexpsForTerminalSimple
 * @memberof wTools
 */

function globRegexpsForTerminalSimple( _glob )
{

  function strForGlob( _glob )
  {

    let result = '';
    _.assert( arguments.length === 1, 'expects single argument' );
    _.assert( _.strIs( _glob ) );

    let w = 0;
    _glob.replace( /(\*\*[\/\\]?)|\?|\*/g, function( matched,a,offset,str )
    {

      result += _.regexpEscape( _glob.substr( w,offset-w ) );
      w = offset + matched.length;

      if( matched === '?' )
      result += '.';
      else if( matched === '*' )
      result += '[^\\\/]*';
      else if( matched.substr( 0,2 ) === '**' )
      result += '.*';
      else _.assert( 0,'unexpected' );

    });

    result += _.regexpEscape( _glob.substr( w,_glob.length-w ) );
    if( result[ 0 ] !== '^' )
    {
      result = _.strPrependOnce( result,'./' );
      result = _.strPrependOnce( result,'^' );
    }
    result = _.strAppendOnce( result,'$' );

    return result;
  }

  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( _.strIs( _glob ) || _.strsAre( _glob ) );

  if( _.strIs( _glob ) )
  _glob = [ _glob ];

  let result = _.entityMap( _glob,( _glob ) => strForGlob( _glob ) );
  result = RegExp( '(' + result.join( ')|(' ) + ')','m' );

  return result;
}

//

function globRegexpsForTerminalOld( src )
{

  _.assert( _.strIs( src ) || _.strsAre( src ) );
  _.assert( arguments.length === 1, 'expects single argument' );

/*
  (\*\*\\\/|\*\*)|
  (\*)|
  (\?)|
  (\[.*\])
*/

  let map =
  {
    0 : '.*', /* doubleAsterix */
    1 : '[^\/]*', /* singleAsterix */
    2 : '.', /* questionMark */
    3 : handleSquareBrackets, /* handleSquareBrackets */
    '{' : '(',
    '}' : ')',
  }

  /* */

  let result = '';

  if( _.strIs( src ) )
  {
    result = adjustGlobStr( src );
  }
  else
  {
    if( src.length > 1 )
    for( let i = 0; i < src.length; i++ )
    {
      let r = adjustGlobStr( src[ i ] );
      result += `(${r})`;
      if( i + 1 < src.length )
      result += '|'
    }
    else
    {
      result = adjustGlobStr( src[ 0 ] );
    }
  }

  result = _.strPrependOnce( result,'\\/' );
  result = _.strPrependOnce( result,'\\.' );

  result = _.strPrependOnce( result,'^' );
  result = _.strAppendOnce( result,'$' );

  return RegExp( result );

  /* */

  function handleSquareBrackets( src )
  {
    debugger;
    src = _.strInsideOf( src, '[', ']' );
    // src = _.strIsolateInsideOrNone( src, '[', ']' );
    /* escape inner [] */
    src = src.replace( /[\[\]]/g, ( m ) => '\\' + m );
    /* replace ! -> ^ at the beginning */
    src = src.replace( /^\\!/g, '^' );
    return '[' + src + ']';
  }

  function curlyBrackets( src )
  {
    debugger;
    src = src.replace( /[\}\{]/g, ( m ) => map[ m ] );
    /* replace , with | to separate regexps */
    src = src.replace( /,+(?![^[|(]*]|\))/g, '|' );
    return src;
  }

  function globToRegexp()
  {
    let args = _.longSlice( arguments );
    let i = args.indexOf( args[ 0 ], 1 ) - 1;

    /* i - index of captured group from regexp is equivalent to key from map  */

    if( _.strIs( map[ i ] ) )
    return map[ i ];
    else if( _.routineIs( map[ i ] ) )
    return map[ i ]( args[ 0 ] );
    else _.assert( 0 );
  }

  function adjustGlobStr( src )
  {
    _.assert( !_.path.isAbsolute( src ) );

    /* espace simple text */
    src = src.replace( /[^\*\[\]\{\}\?]+/g, ( m ) => _.regexpEscape( m ) );
    /* replace globs with regexps from map */
    src = src.replace( /(\*\*\\\/|\*\*)|(\*)|(\?)|(\[.*\])/g, globToRegexp );
    /* replace {} -> () and , -> | to make proper regexp */
    src = src.replace( /\{.*\}/g, curlyBrackets );
    // src = src.replace( /\{.*\}+(?![^[]*\])/g, curlyBrackets );

    return src;
  }

}

//

function _globRegexpForTerminal( glob, filePath, basePath )
{
  let self = this;
  _.assert( arguments.length === 3 );
  if( basePath === null )
  basePath = filePath;
  if( filePath === null )
  filePath = basePath;
  if( basePath === null )
  basePath = filePath = this.fromGlob( glob );
  return self._globRegexpFor2.apply( self, [ glob, filePath, basePath ] ).terminal;
}

//

// let _globRegexpsForTerminal = _.routineVectorize_functor( _globRegexpForTerminal );
let _globRegexpsForTerminal = _.routineVectorize_functor
({
  routine : _globRegexpForTerminal,
  select : 3,
});

function globRegexpsForTerminal()
{
  let result = _globRegexpsForTerminal.apply( this, arguments );
  return _.regexpsAny( result );
}

//

function _globRegexpForDirectory( glob, filePath, basePath )
{
  let self = this;
  _.assert( arguments.length === 3 );
  if( basePath === null )
  basePath = filePath;
  if( filePath === null )
  filePath = basePath;
  if( basePath === null )
  basePath = filePath = this.fromGlob( glob );
  return self._globRegexpFor2.apply( self, [ glob, filePath, basePath ] ).directory;
}

//

// let _globRegexpsForDirectory = _.routineVectorize_functor( _globRegexpForDirectory );

let _globRegexpsForDirectory = _.routineVectorize_functor
({
  routine : _globRegexpForDirectory,
  select : 3,
});

function globRegexpsForDirectory()
{
  let result = _globRegexpsForDirectory.apply( this, arguments );
  return _.regexpsAny( result );
}

//

function _globRegexpFor2( glob, filePath, basePath )
{
  let self = this;

  _.assert( _.strIs( glob ) );
  _.assert( _.strIs( filePath ) );
  _.assert( _.strIs( basePath ) );
  _.assert( arguments.length === 3, 'expects single argument' );

  glob = this.join( filePath, glob );

  // let isRelative = this.isRelative( glob );
  let related = this.relateForGlob( glob, filePath, basePath );
  let maybeHere = '';
  // let maybeHere = '\\.?';

  // if( !isRelative || glob === '.' )
  // maybeHere = '';

  // if( isRelative )
  // glob = this.undot( glob );

  let hereEscapedStr = self._globSplitToRegexpSource( self._hereStr );
  let downEscapedStr = self._globSplitToRegexpSource( self._downStr );
  // let prefix = self.split( related[ 0 ] );

  let result = Object.create( null );
  result.directory = [];
  result.terminal = [];

  // debugger;
  for( let r = 0 ; r < related.length ; r++ )
  {
    related[ r ] = this.split( related[ r ] ).map( ( e, i ) => self._globSplitToRegexpSource( e ) );

    result.directory.push( self._globRegexpSourceSplitsJoinForDirectory( related[ r ] ) );
    result.terminal.push( self._globRegexpSourceSplitsJoinForTerminal( related[ r ] ) );

    // let groups = self._globSplitsToRegexpSourceGroups( related[ r ] );
    // result.directory.push( write( groups, 0, 1 ) );
    // result.terminal.push( write( groups, 0, 0 ) );

  }
  // debugger;

  result.directory = '(?:(?:' + result.directory.join( ')|(?:' ) + '))';
  result.directory = _.regexpsJoin([ '^', result.directory, '$' ]);
  result.terminal = '(?:(?:' + result.terminal.join( ')|(?:' ) + '))';
  result.terminal = _.regexpsJoin([ '^', result.terminal, '$' ]);

  // result.directory = [ _.regexpsAtLeastFirstOnly( prefix ).source, write( groups, 0, 1 ) ];
  // result.terminal = write( groups, 0, 0 );
  //
  // result.directory = '(?:(?:' + result.directory.join( ')|(' ) + '))';
  // // if( maybeHere )
  // // result.directory = '(?:' + result.directory + ')?';
  // result.directory = _.regexpsJoin([ '^', maybeHere, result.directory, '$' ]);
  //
  // result.terminal = _.regexpsJoin([ '^', maybeHere, result.terminal, '$' ]);

  return result;

  /* - */

  function write( groups, written, forDirectory )
  {

    if( _.strIs( groups ) )
    {
      if( groups === '.*' )
      return '(?:/' + groups + ')?';
      else if( written === 0 && ( groups === downEscapedStr || groups === hereEscapedStr ) )
      return groups;
      else if( groups === hereEscapedStr )
      return '(?:/' + groups + ')?';
      else
      return '/' + groups;
    }

    let joined = [];
    for( var g = 0 ; g < groups.length ; g++ )
    {
      let group = groups[ g ];
      let text = write( group, written, forDirectory );
      if( _.arrayIs( group ) )
      if( group[ 0 ] !== downEscapedStr )
      text = '(?:' + text + ')?';
      if( _.arrayIs( group ) && groups[ g ] === downEscapedStr )
      text = '(?:' + text + ')?';
      joined[ g ] = text;
      written += 1;
    }

    let result;

    if( forDirectory )
    // result = _.regexpsAtLeastFirst( joined ).source;
    result = _.regexpsAtLeastFirstOnly( joined ).source;
    else
    result = joined.join( '' );

    return result;
  }

}

//

let _globRegexpsFor2 = _.routineVectorize_functor
({
  routine : _globRegexpFor2,
  select : 3,
});

function globRegexpsFor2()
{
  let r = _globRegexpsFor2.apply( this, arguments );
  if( _.arrayIs( r ) )
  {
    let result = Object.create( null );
    result.terminal = r.map( ( e ) => e.terminal );
    result.directory = r.map( ( e ) => e.directory );
    // result.terminal = _.regexpsAny( r.map( ( e ) => e.terminal ) );
    // result.directory = _.regexpsAny( r.map( ( e ) => e.directory ) );
    return result;
  }
  return r;
}

//
//
// function _globRegexpFor( srcGlob )
// {
//   let self = this;
//
//   _.assert( _.strIs( srcGlob ) );
//   _.assert( arguments.length === 1, 'expects single argument' );
//
//   let isRelative = this.isRelative( srcGlob );
//   let maybeHere = '\\.?';
//
//   if( !isRelative || srcGlob === '.' )
//   maybeHere = '';
//
//   if( isRelative )
//   srcGlob = this.undot( srcGlob );
//
//   let hereEscapedStr = self._globSplitToRegexpSource( self._hereStr );
//   let downEscapedStr = self._globSplitToRegexpSource( self._downStr );
//   let groups = self._globSplitsToRegexpSourceGroups( srcGlob );
//   let result = Object.create( null )
//
//   result.directory = write( groups, 0, 1 );
//   result.terminal = write( groups, 0, 0 );
//
//   if( maybeHere )
//   result.directory = '(?:' + result.directory + ')?';
//   result.directory = _.regexpsJoin([ '^', maybeHere, result.directory, '$' ]);
//
//   result.terminal = _.regexpsJoin([ '^', maybeHere, result.terminal, '$' ]);
//
//   return result;
//
//   /* - */
//
//   function write( groups, written, forDirectory )
//   {
//
//     if( _.strIs( groups ) )
//     {
//       if( groups === '.*' )
//       return '(?:/' + groups + ')?';
//       else if( written === 0 && ( groups === downEscapedStr || groups === hereEscapedStr ) )
//       return groups;
//       else if( groups === hereEscapedStr )
//       return '(?:/' + groups + ')?';
//       else
//       return '/' + groups;
//     }
//
//     let joined = [];
//     for( var g = 0 ; g < groups.length ; g++ )
//     {
//       let group = groups[ g ];
//       let text = write( group, written, forDirectory );
//       if( _.arrayIs( group ) )
//       text = '(?:' + text + ')?';
//       if( _.arrayIs( group ) && groups[ g ] === downEscapedStr )
//       text = '(?:' + text + ')?';
//       joined[ g ] = text;
//       written += 1;
//     }
//
//     let result;
//
//     if( forDirectory )
//     result = _.regexpsAtLeastFirstOnly( joined ).source;
//     else
//     result = joined.join( '' );
//
//     return result;
//   }
//
// }
//
// //
//
// let _globRegexpsFor = _.routineVectorize_functor( _globRegexpFor );
// function globRegexpsFor()
// {
//   let r = _globRegexpsFor.apply( this, arguments );
//   if( _.arrayIs( r ) )
//   {
//     let result = Object.create( null );
//     result.terminal = _.regexpsAny( r.map( ( e ) => e.terminal ) );
//     result.directory = _.regexpsAny( r.map( ( e ) => e.directory ) );
//     return result;
//   }
//   return r;
// }
//
//

function globToRegexp( glob )
{

  _.assert( _.strIs( glob ) || _.regexpIs( glob ) );
  _.assert( arguments.length === 1 );

  if( _.regexpIs( glob ) )
  return glob;

  let str = this._globSplitToRegexpSource( glob );

  let result = new RegExp( str );

  return result;
}

// //
//
// function globSplit( glob )
// {
//   _.assert( arguments.length === 1, 'expects single argument' );
//
//   debugger;
//
//   return _.path.split( glob );
// }

//

function _globSplitsToRegexpSourceGroups( globSplits )
{
  let self = this;

  _.assert( _.arrayIs( globSplits ) );
  // _.assert( _.strIs( srcGlob ) );
  // _.assert( _.path.isRelative( srcGlob ) );
  _.assert( arguments.length === 1, 'expects single argument' );

  // let isRelative = this.isRelative( srcGlob );
  // let maybeHere = '(?:\\.|\\./)?';
  // if( !isRelative || srcGlob === '.' )
  // maybeHere = '';
  //
  // if( isRelative )
  // srcGlob = this.undot( srcGlob );

  // let splits = this.split( srcGlob );

  // splits = splits.map( ( e, i ) => self._globSplitToRegexpSource( e ) );

  _.assert( globSplits.length >= 1 );

  let s = 0;
  let depth = 0;
  let hereEscapedStr = self._globSplitToRegexpSource( self._hereStr );
  let downEscapedStr = self._globSplitToRegexpSource( self._downStr );
  let levels = levelsEval( globSplits );

  for( let s = 0 ; s < globSplits.length ; s++ )
  {
    let split = globSplits[ s ];
    if( _.strHas( split, '.*' ) )
    {
      let level = levels[ s ];
      if( level < 0 )
      {
        for( let i = s ; i < globSplits.length ; i++ )
        levels[ i ] += 1;
        levels.splice( s, 0, level );
        globSplits.splice( s, 0, '[^\/]*' );
      }
      else
      {
        while( levels.indexOf( level, s+1 ) !== -1 )
        {
          _.assert( 0, 'not tested' ); xxx
          levels.splice( s+1, 0, level );
          globSplits.splice( s+1, 0, '[^\/]*' );
          for( let i = s+1 ; i < globSplits.length ; i++ )
          levels[ i ] += 1;
        }
      }
    }
  }

  let groups = groupWithLevels( globSplits.slice(), levels, 0 );

  return groups;

  /* - */

  function levelsEval()
  {
    let result = [];
    let level = 0;
    for( let s = 0 ; s < globSplits.length ; s++ )
    {
      split = globSplits[ s ];
      if( split === downEscapedStr )
      level -= 1;
      result[ s ] = level;
      if( split !== downEscapedStr )
      level += 1;
    }
    return result;
  }

  /* - */

  function groupWithLevels( globSplits, levels, first )
  {
    let result = [];

    for( let b = first ; b < globSplits.length-1 ; b++ )
    {
      let level = levels[ b ];
      let e = levels.indexOf( level, b+1 );

      if( e === -1 /*|| ( b === 0 && e === globSplits.length-1 )*/ )
      {
        continue;
      }
      else
      {
        let inside = globSplits.splice( b, e-b+1, null );
        globSplits[ b ] = inside;
        inside = levels.splice( b, e-b+1, null );
        levels[ b ] = inside;
        groupWithLevels( globSplits[ b ], levels[ b ], 1 );
      }

    }

    return globSplits;
  }

}

//

function _globSplitToRegexpSource( src )
{

  _.assert( _.strIs( src ) );
  _.assert( arguments.length === 1, 'expects single argument' );
  _.assert( !_.strHas( src, this._downStr ) || src === this._downStr, 'glob should not has splits with ".." combined with something' );

  let transformation1 =
  [
    [ /\[(.+?)\]/g, handleSquareBrackets ], /* square brackets */
    [ /\{(.*)\}/g, handleCurlyBrackets ], /* curly brackets */
  ]

  let transformation2 =
  [
    [ /\.\./g, '\\.\\.' ], /* double dot */
    [ /\./g, '\\.' ], /* dot */
    [ /([!?*@+]*)\((.*?(?:\|(.*?))*)\)/g, hanleParentheses ], /* parentheses */
    [ /\/\*\*/g, '(?:\/.*)?', ], /* slash + double asterix */
    [ /\*\*/g, '.*', ], /* double asterix */
    [ /(\*)/g, '[^\/]*' ], /* single asterix */
    [ /(\?)/g, '.', ], /* question mark */
  ]

  let result = adjustGlobStr( src );

  return result;

  /* */

  function handleCurlyBrackets( src, it )
  {
    throw _.err( 'Globs with curly brackets are not supported' );
  }

  /* */

  function handleSquareBrackets( src, it )
  {
    let inside = it.groups[ 1 ];
    /* escape inner [] */
    inside = inside.replace( /[\[\]]/g, ( m ) => '\\' + m );
    /* replace ! -> ^ at the beginning */
    inside = inside.replace( /^!/g, '^' );
    if( inside[ 0 ] === '^' )
    inside = inside + '\/';
    return '[' + inside + ']';
  }

  /* */

  function hanleParentheses( src, it )
  {

    let inside = it.groups[ 2 ].split( '|' );
    let multiplicator = it.groups[ 1 ];
    multiplicator = _.strReverse( multiplicator );
    if( multiplicator === '*' )
    multiplicator += '?';

    _.assert( _.strCount( multiplicator, '!' ) === 0 || multiplicator === '!' );
    _.assert( _.strCount( multiplicator, '@' ) === 0 || multiplicator === '@' );

    let result = '(?:' + inside.join( '|' ) + ')';
    if( multiplicator === '@' )
    result = result;
    else if( multiplicator === '!' )
    result = '(?:(?!(?:' + result + '|\/' + ')).)*?';
    else
    result += multiplicator;

    /* (?:(?!(?:abc)).)+ */

    return result;
  }

  // /* */
  //
  // function curlyBrackets( src )
  // {
  //   debugger;
  //   src = src.replace( /[\}\{]/g, ( m ) => map[ m ] );
  //   /* replace , with | to separate regexps */
  //   src = src.replace( /,+(?![^[|(]*]|\))/g, '|' );
  //   return src;
  // }

  /* */

  function adjustGlobStr( src )
  {
    let result = src;

    // _.assert( !_.path.isAbsolute( result ) );

    result = _.strReplaceAll( result, transformation1 );
    result = _.strReplaceAll( result, transformation2 );

    // /* espace ordinary text */
    // result = result.replace( /[^\*\+\[\]\{\}\?\@\!\^\(\)]+/g, ( m ) => _.regexpEscape( m ) );

    // /* replace globs with regexps from map */
    // result = result.replace( /(\*\*\\\/|\*\*)|(\*)|(\?)|(\[.*\])/g, globToRegexp );

    // /* replace {} -> () and , -> | to make proper regexp */
    // result = result.replace( /\{.*\}/g, curlyBrackets );
    // result = result.replace( /\{.*\}+(?![^[]*\])/g, curlyBrackets );

    return result;
  }

}

//

function _globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits )
{
  let result = '';
  // debugger;
  let splits = globRegexpSourceSplits.map( ( split, s ) =>
  {
    if( s > 0 )
    if( split == '.*' )
    split = '(?:(?:^|/)' + split + ')?';
    else
    split = '(?:^|/)' + split;
    return split;
  });

  // for( let g = 0 ; g < globRegexpSourceSplits.length ; g++ )
  // {
  //   let split = globRegexpSourceSplits[ g ];
  //   if( g > 0 && split !== '.*' && globRegexpSourceSplits[ g-1 ] !== '.*' )
  //   result += '/';
  //   result += split;
  // }

  result = splits.join( '' );
  // result = '^' + splits.join( '' ) + '$';
  return result;
}

//

function _globRegexpSourceSplitsJoinForDirectory( globRegexpSourceSplits )
{
  let result = '';
  let splits = globRegexpSourceSplits.map( ( split, s ) =>
  {
    if( s > 0 )
    if( split == '.*' )
    split = '(?:(?:^|/)' + split + ')?';
    else
    split = '(?:^|/)' + split;
    return split;
  });
  result = _.regexpsAtLeastFirst( splits ).source;
  return result;
}

//

function relateForGlob( glob, filePath, basePath )
{
  let self = this;
  let result = [];

  _.assert( arguments.length === 3, 'expects exactly three argument' );
  _.assert( _.strIs( glob ) );
  _.assert( _.strIs( filePath ) );
  _.assert( _.strIs( basePath ) );

  let glob1 = this.join( filePath, glob );
  // let downGlob = this.relative( basePath, glob1 );
  let r1 = this.relativeUndoted( basePath, filePath );
  let r2 = this.relativeUndoted( filePath, glob1 );
  let downGlob = this.dot( this.normalize( this.join( r1, r2 ) ) );

  result.push( downGlob );

  // if( _.strBegins( filePath, basePath ) )
  // return result;

  /* */

  if( !_.strBegins( basePath, filePath ) || basePath === filePath )
  return result;

  let common = this.common([ glob1, basePath ]);
  let glob2 = this.relative( common, glob1 );
  basePath = this.relative( common, basePath );

  if( basePath === '.' )
  {

    result.push( ( glob2 === '' || glob2 === '.' ) ? '.' : './' + glob2 );

  }
  else
  {

    let globSplits = this.split( glob2 );
    let globRegexpSourceSplits = globSplits.map( ( e, i ) => self._globSplitToRegexpSource( e ) );
    let s = 0;
    while( s < globSplits.length )
    {
      let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
      if( globSliced.test( basePath ) )
      {
        let splits = _.strHas( globSplits[ s ], '**' ) ? globSplits.slice( s ) : globSplits.slice( s+1 );
        let glob3 = splits.join( '/' );
        result.push( glob3 === '' ? '.' : './' + glob3  );
      }

      s += 1;
    }

  }

  /* */

  return result;

  // let common = this.common([ glob1, basePath ]);
  // let mandatory = this.dot( this.relative( basePath, glob1 ) );
  //
  // let optional;
  // if( common === basePath )
  // {
  //   let r1 = this.relative( common, '/' );
  //   let r2 = this.relative( '/', basePath );
  //   if( r1 === '.' )
  //   r1 = '';
  //   if( r2 === '.' )
  //   r2 = '';
  //   optional = this.join( r1, r2 );
  // }
  // else
  // {
  //   optional = this.relative( basePath, common );
  // }
  //
  // debugger;
  //
  // return [ optional, mandatory ];
}

/*
common : common glob base
common : /src2
glob : glob relative base
glob : **
optional : file relative common + common relative file
optional : ../src2
*/

//

function pathsRelateForGlob( filePath, oldPath, newPath )
{
  let length;

  let multiplied = _.multipleAll([ filePath, oldPath, newPath ]);

  filePath = multiplied[ 0 ];
  oldPath = multiplied[ 1 ];
  newPath = multiplied[ 2 ];

  _.assert( arguments.length === 3, 'expects exactly three argument' );

  if( _.arrayIs( filePath ) )
  {
    let result = [];
    for( let f = 0 ; f < filePath.length ; f++ )
    result[ f ] = this.relateForGlob( filePath[ f ], oldPath[ f ], newPath[ f ] );
    return result;
  }

  return this.relateForGlob( filePath, oldPath, newPath );
}

// --
// fields
// --

let Fields =
{

  _rootStr : '/',
  _upStr : '/',
  _hereStr : '.',
  _downStr : '..',
  _hereUpStr : null,
  _downUpStr : null,

  _upEscapedStr : null,
  _butDownUpEscapedStr : null,
  _delDownEscapedStr : null,
  _delDownEscaped2Str : null,
  _delUpRegexp : null,
  _delHereRegexp : null,
  _delDownRegexp : null,
  _delDownFirstRegexp : null,
  _delUpDupRegexp : null,

  fileProvider : null,
  path : Self,

}

// --
// routines
// --

let Routines =
{

  // internal

  Init : Init,
  CloneExtending : CloneExtending,

  _pathMultiplicator_functor : _pathMultiplicator_functor,
  _filterNoInnerArray : _filterNoInnerArray,
  _filterOnlyPath : _filterOnlyPath,

  // path tester

  is : is,
  are : are,
  like : like,
  isSafe : isSafe,
  isNormalized : isNormalized,
  isAbsolute : isAbsolute,
  isRelative : isRelative,
  isRoot : isRoot,
  isRefined : isRefined,
  isDotted : isDotted,

  // normalizer

  refine : refine,
  pathsRefine : pathsRefine,
  pathsOnlyRefine : pathsOnlyRefine,

  _pathNormalize : _pathNormalize,
  normalize : normalize,
  pathsNormalize : pathsNormalize,
  pathsOnlyNormalize : pathsOnlyNormalize,

  normalizeTolerant : normalizeTolerant,

  dot : dot,
  pathsDot : pathsDot,
  pathsOnlyDot : pathsOnlyDot,
  undot : undot,
  pathsUndot : pathsUndot,
  pathsOnlyUndot : pathsOnlyUndot,

  trail : trail,
  pathsTrail : pathsTrail,
  pathsOnlyTrail : pathsOnlyTrail,
  untrail : untrail,
  pathsUntrail : pathsUntrail,
  pathsOnlyUntrail : pathsOnlyUntrail,

  _pathNativizeWindows : _pathNativizeWindows,
  _pathNativizeUnix : _pathNativizeUnix,
  nativize : nativize,

  // path join

  _pathJoin_body : _pathJoin_body,
  _pathsJoin_body : _pathsJoin_body,

  join : join,
  pathsJoin : pathsJoin,

  reroot : reroot,
  pathsReroot : pathsReroot,
  pathsOnlyReroot : pathsOnlyReroot,

  resolve : resolve,
  pathsResolve : pathsResolve,
  pathsOnlyResolve : pathsOnlyResolve,

  // path cut off

  split : split,
  _pathSplit : _pathSplit,

  dir : dir,
  pathsDir : pathsDir,
  pathsOnlyDir : pathsOnlyDir,

  prefixGet : prefixGet,
  pathsPrefixesGet : pathsPrefixesGet,
  pathsOnlyPrefixesGet : pathsOnlyPrefixesGet,

  name : name,
  pathsName : pathsName,
  pathsOnlyName : pathsOnlyName,

  fullName : fullName,

  withoutExt : withoutExt,
  pathsWithoutExt : pathsWithoutExt,
  pathsOnlyWithoutExt : pathsOnlyWithoutExt,

  changeExt : changeExt,
  pathsChangeExt : pathsChangeExt,
  pathsOnlyChangeExt : pathsOnlyChangeExt,

  ext : ext,
  pathsExt : pathsExt,
  pathsOnlyExt : pathsOnlyExt,

  exts : exts,

  // path transformer

  current : current,
  from : from,
  pathsFrom : pathsFrom,

  _relative : _relative,
  relative : relative,
  relativeUndoted : relativeUndoted,
  pathsRelative : pathsRelative,
  pathsOnlyRelative : pathsOnlyRelative,

  _common : _common,
  common : common,
  _pathsCommon : _pathsCommon,
  pathsCommon : pathsCommon,
  pathsOnlyCommon : pathsOnlyCommon,

  rebase : rebase,

  // relate : relate,
  // pathsRelate : pathsRelate,

  // glob

  isGlob : isGlob,
  fromGlob : fromGlob,

  globRegexpsForTerminalSimple : globRegexpsForTerminalSimple,
  globRegexpsForTerminalOld : globRegexpsForTerminalOld,

  _globRegexpForTerminal : _globRegexpForTerminal,
  _globRegexpsForTerminal : _globRegexpsForTerminal,
  globRegexpsForTerminal : globRegexpsForTerminal,

  _globRegexpForDirectory : _globRegexpForDirectory,
  _globRegexpsForDirectory : _globRegexpsForDirectory,
  globRegexpsForDirectory : globRegexpsForDirectory,

  _globRegexpFor2 : _globRegexpFor2,
  _globRegexpsFor2 : _globRegexpsFor2,
  globRegexpsFor2 : globRegexpsFor2,

  // _globRegexpFor : _globRegexpFor,
  // _globRegexpsFor : _globRegexpsFor,
  // globRegexpsFor : globRegexpsFor,

  globToRegexp : globToRegexp,
  globsToRegexp : _.routineVectorize_functor( globToRegexp ),

  // globSplit : globSplit,
  _globSplitsToRegexpSourceGroups : _globSplitsToRegexpSourceGroups,
  _globSplitToRegexpSource : _globSplitToRegexpSource,
  _globRegexpSourceSplitsJoinForTerminal : _globRegexpSourceSplitsJoinForTerminal,
  _globRegexpSourceSplitsJoinForDirectory : _globRegexpSourceSplitsJoinForDirectory,

  relateForGlob : relateForGlob,
  pathsRelateForGlob : pathsRelateForGlob,

}

_.mapSupplement( Self, Fields );
_.mapSupplement( Self, Routines );

Self.Init();

// --
// export
// --

if( typeof module !== 'undefined' )
if( _global_.WTOOLS_PRIVATE )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
