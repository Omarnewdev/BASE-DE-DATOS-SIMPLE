(******************************************************************************)
(*============================================================================*)
(*                              UNIDAD UComando                               *)
(*============================================================================*)
(*Esta unidad permite trabajar con comandos desde la entrada estándar, lo cual
facilita el ingreso de datos por parte del usuario desde la misma, evitando
tener que estar leyendo línea por línea lo que este ingresa. Esta forma de
ingresar datos es ampliamente utilizada hoy día por la consola de Windows, y
más aún, en los sistemas Linux y otros basados en Unix, donde el uso de la
terminal o consola es de lo más habitual. También se utiliza mucho en MySQL y
otros motores de datos.

Un COMANDO en este modelo no es otra cosa que una línea de texto en la entrada
estándar con el siguiente formato:

NOMBRE_COMANDO PARAMETRO1 PARAMETRO2 ... PARAMETROn

Por tanto, un comando básicamente separa las palabras de la entrada estándar. La
primera palabra es el nombre del comando, y el resto sus parámetros.

Por ejemplo, en Windows, el comando para copiar directorios en la consola se
llama XCOPY, y su formato es:

XCOPY DIRECTORIO_ORIGINAL DIRECTORIO_DESTINO

Recibe por tanto dos parámetros, el directorio de origen (desde donde vamos a
copiar, y el directorio de destino). También puede recibir más parámetros aún,
que indicarán permisos y otros detalles. En Linux, el comando de copiado en
vez de llamarse XCOPY se llama CP, pero usa el mismo formato.

cp DIRECTORIO_ORIGINAL DIRECTORIO_DESTINO

Esta unidad, dado todo el texto de la entrada estándar, permitirá separar las
palabras ingresadas para distinguir el nombre del comando, y luego uno a uno
sus parámetros (si los hubiera).

Admite además trabajar con parámetros compuestos. Por ejemplo, tanto en Windows
como en Linux, el comando para cambiar de directorio en la terminal se llama cd
(change directory), el cual recibe un solo parámetro: la dirección del directorio
al que queremos ir. Por ejemplo:

cd C:\Juegos\Buscaminas

Ahora bien ¿Qué pasa cuando una carpeta contiene espacios en su nombre? Por
ejemplo, si en vez de "Juegos" se llama "Mis juegos":

cd C:\Mis juegos\Buscaminas

El comando anterior no funcionará, porque el espacio en blanco funciona como
separador, y por tanto habría dos parámetros: "C:\Mis" y "juegos\Buscaminas".
Para solucionar esto, tanto en Windows como en Linux, ha de usarse la comilla
simple en el texto para indicar que TODO es un solo parámetro:

cd 'C:\Mis juegos\Buscaminas'

Esta unidad admite parámetros compuestos, encerrándolos entre comillas dobles ("),
por tanto, un comando así sería permitido:

INGRESAR "Maria del Rosario" "De Leon"

El comando se llama INGRESAR, y recibe dos parámetros "Maria del Rosario" y
"De Leon". Ambos parámetros son compuestos porque tienen espacios dentro, pero
se leen como uno solo.

Si solamente utilizáramos los espacios en blanco como separadores, tendríamos
al menos 5 parámetros en nuestro comando, y eso estaría mal.

Esta unidad, entonces, solamente distingue la primera palabra como el nombre de
un comando y luego le asigna una lista de parámetros (que también son palabras)
y nada más. ¿Qué hace cada comando? Eso habrá que programarlo en cada programa
individualmente.*)
unit UComando;

interface

const
  MAX_PARAM_COMANDO= 25; //La cantidad máxima de parámetros para un comando.
  COMILLAS= #34; //Caracter de comillas dobles, para parámetros compuestos.

type
  (*Un parámetro en sí es solamente un dato, una palabra. El tipo TParametro
  permite distinguir si ese dato es un String o si es numérico, ya que eso
  resultará muy útil.

  Tú solamente deberás utilizar las operaciones disponibles para este tipo de
  datos, no sus atributos directamente.*)
  TParametro= record
      datoString: String;
      datoNumerico: integer;
      esNumero: boolean;
  end;

  (*Una lista de parámetros es justamente una lista con una cantidad finita
  de parámetros en ella.
  Este tipo de datos no deberás usarlo directamente, solo válete de las operaciones
  disponibles debajo.*)
  TListParametros= record
      argumentos: array[1..MAX_PARAM_COMANDO] of TParametro;
      cantidad: byte;
  end;

  (*Un comando es un tipo de datos que tiene un nombre (por ejemplo el comando
  XCOPY) y luego una lista de parámetros recibidos. Siguiendo el ejemplo anterior,
  si el usuario ingresa:

  INGRESAR "Maria del Rosario" "De Leon"

  El nombre del comando será INGRESAR y luego tendría dos parámetros:
  * Maria del Rosario
  * De Leon

  Tú solamente deberás utilizar las operaciones disponibles para este tipo de
  datos, no sus atributos directamente.*)
  TComando= record
      nombreComando: String;
      haySiguiente: boolean;
      listaParametros: TListParametros;
      puntero: byte;
  end;

  {==================================================================
  |                OPERACIONES PARA EL TIPO TParametro              |
  ===================================================================}
  {Retorna TRUE si el parámetro p es de tipo numérico, FALSE si no.
  Esta operación es análoga a esParametroNumerico}
  function esParametroString(const p: TParametro): boolean;

  {Retorna TRUE si el parámetro p es de tipo numérico, FALSE si no.
  Esta operación es análoga a esParametroString}
  function esParametroNumerico(const p: TParametro): boolean;

  {En caso de que p sea un parámetro de tipo numérico, asigna a n el
  número contenido en p y retorna TRUE. De lo contrario, retorna FALSE.}
  function obtenerNumero(var n: byte; const p: TParametro): boolean;

  {Retorna el contenido de un parámetro como un String, sin importar
  si el parámetro p es numérico o no, siempre se obtiene un String.
  Si, por ejemplo, el parámetro es numérico y tiene el valor 89, se
  obtenddrá el String '89'.}
  function obtenerString(const p: TParametro): String;

  {==================================================================
  |                 OPERACIONES PARA EL TIPO TComando                |
  ===================================================================}

  {Crea un comando a partir de una cadena de caracteres. Esta operación
  separa el nombre del comando y sus parámetros, creando una lista de
  éstos de forma correcta. Se utiliza el espacio como separador de
  parámetros, salvo si hay comillas, en ese caso las comillas
  funcionan como separador hasta que se cierren. Por ejemplo:

  1) COMANDO1 Arg1 Arg2 Dato3
  En este caso no hay comillas, por tanto el nombre del comando que se
  creará es COMANDO1 y sus tres argumentos serán Arg1, Arg2 y Dato3,
  todos de tipo String.

  2) COMANDO2 "Maria del Rosario" "De Leon" 30 24
  En este caso el nombre del comando es COMANDO2, y tiene tres argumentos:
  Maria del rosario: es el primer argumento de tipo String.
  De Leon: es el segundo argumento de tipo String.
  30: es el tercer argumento de tipo numérico.
  24: es el cuarto argumento de tipo numérico.

  El formato de entrada debe ser correcto, siguiendo estas directivas:

  * El nombre del comando no puede ser compuesto, es solo una palabra.
  * Si se abren comillas éstas deben cerrarse.
  * Si no hay comillas, el espacio en blanco se usa como separador, incluso
  si hay más de un espacio en blanco seguido.}
  function crearComando(entrada: String): TComando;

  {Retorna el nombre del comando c como un String}
  function nombreComando(const c: TComando): String;

  {Retorna TRUE si hay al menos un parámetro más por ser leído en la lista
  de parámetros de c, FALSE si no hay ninguno.}
  function haySiguienteParametro(const c: TComando): boolean;

  {Retorna el siguiente parámetro disponible. Debe haber un siguiente
  parámetro, de lo contrario se retorna un parámetro con el contenido
  NULL como String.}
  function siguienteParametro(var c: TComando): TParametro;

  {Regresa la lista de parámetros al inicio para poder recorrerla nuevamente.}
  procedure resetearParametros(var c: TComando);

  {Retorna la cantidad de parámetros disponibles para el comando en
  cuestión.}
  function cantidadParametros(const c: TComando): byte;

implementation

uses strutils, character, sysutils;

function esParametroString(const p: TParametro): boolean;
begin
    result:= not p.esNumero;
end;

function esParametroNumerico(const p: TParametro): boolean;
begin
    result:= p.esNumero;
end;

function obtenerNumero(var n: byte; const p: TParametro): boolean;
begin
    if esParametroNumerico(p) then begin
      n:= p.datoNumerico;
      result:= true;
    end else begin
      result:= false;
    end;
end;

function obtenerString(const p: TParametro): String;
begin
    result:= p.datoString;
end;

{Esta operación es privada y no es accesible desde fuera de la unidad.
Agrega un nuevo parámetro a la lista de parámetros del comando c.}
procedure agregarParametro(value: String; var c: TComando);
var newParam: TParametro;

begin
    if  TryStrToInt(value,newParam.datoNumerico) then begin
        newParam.datoNumerico:= StrToInt(value);
        newParam.esNumero:= true;
        newParam.datoString:= value;
    end else begin
        newParam.esNumero:= false;
        newParam.datoString:= value;
    end;

    c.listaParametros.cantidad+= 1;
    c.listaParametros.argumentos[c.listaParametros.cantidad]:= newParam;
end;

function crearComando(entrada: String): TComando;
var i, cantidadPalabras: byte;
    return: TComando;
    nextParam, palabra: String;
    isCompuesto: boolean;
begin
   cantidadPalabras:= WordCount(entrada,[' ']);

   return.puntero:= 0;
   return.listaParametros.cantidad:= 0;
   return.nombreComando:= ExtractWord(1,entrada,[' ']);
   isCompuesto:=false;
   for i:=2 to cantidadPalabras do begin
       palabra:= ExtractWord(i,entrada,[' ']);
       if AnsiStartsText(COMILLAS,palabra) and AnsiEndsText(COMILLAS,palabra) then begin
           nextParam:= DelChars(palabra,COMILLAS);
           isCompuesto:= false;
       end else if AnsiStartsText(COMILLAS,palabra) and not isCompuesto then begin
           isCompuesto:= true;
           nextParam:= DelChars(palabra,COMILLAS);
       end else if AnsiEndsText(COMILLAS,palabra) and isCompuesto then begin
           isCompuesto:= false;
           nextParam:= nextParam+' '+DelChars(palabra,COMILLAS);
       end else if isCompuesto then begin
           nextParam:= nextParam+' '+palabra;
       end else if not isCompuesto then begin
           nextParam:= palabra;
       end;

       if not isCompuesto then begin
           agregarParametro(nextParam,return);
       end;
   end;
   result:= return;
end;

function nombreComando(const c: TComando): String;
begin
    result:= c.nombreComando;
end;

function haySiguienteParametro(const c: TComando): boolean;
begin
    result:= c.puntero<cantidadParametros(c);
end;

function siguienteParametro(var c: TComando): TParametro;
begin
   if haySiguienteParametro(c) then begin
       c.puntero+= 1;
       result:= c.listaParametros.argumentos[c.puntero];
   end else begin
       result.datoString:= 'NULL';
       result.esNumero:= false;
   end;
end;

procedure resetearParametros(var c: TComando);
begin
  c.puntero:= 0;
end;

function cantidadParametros(const c: TComando): byte;
begin
    result:= c.listaParametros.cantidad;
end;



end.

