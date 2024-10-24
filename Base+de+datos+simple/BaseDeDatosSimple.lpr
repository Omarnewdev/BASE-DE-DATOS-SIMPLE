program BaseDeDatosSimple;

uses ucomando, sysutils;

const
      (*Lista de comandos en String*)
      COMANDO_NUEVO_TEXTO= 'NUEVO';
      COMANDO_MODIFICAR_TEXTO= 'MODIFICAR';
      COMANDO_ELIMINAR_TEXTO= 'ELIMINAR';
      COMANDO_BUSCAR_TEXTO= 'BUSCAR';
      COMANDO_OPTIMIZAR_TEXTO= 'OPTIMIZAR';
      COMANDO_ESTADOSIS_TEXTO= 'ESTADOSIS';
      COMANDO_SALIR_TEXTO= 'SALIR';
      PARAMETRO_ELIMINAR_DOC= '-D';
      PARAMETRO_ELIMINAR_TODO= '-T';

      (*Formatos para imprimir datos de salida como una tabla*)
      FORMAT_ID= '%6s';
      FORMAT_DOCUMENTO= '%11s';
      FORMAT_NOMBRE_APELLIDO= '%21s';
      FORMAT_EDAD_PESO= '%6s';
      COLUMNA_ID= 'ID';
      COLUMNA_DOCUMENTO= 'DOCUMENTO';
      COLUMNA_NOMBRE= 'NOMBRE';
      COLUMNA_APELLIDO= 'APELLIDO';
      COLUMNA_EDAD= 'EDAD';
      COLUMNA_PESO= 'PESO';

      (*Simplemente el prompt de entrada en la consola*)
      PROMPT= '>> ';

      (*Nombre de archivo de la base de datos.*)
      BASEDEDATOS_NOMBRE_REAL= 'data.dat';
      (*Nombre de archivo temporal de la base de datos*)
      BASEDEDATOS_NOMBRE_TEMPORAL= 'tempDataBase_ka.tmpka';

type
  {Identifica a los comandos admitidos por el sistema.
   * NUEVO: Permitirá crear nuevos registros.
   * MODIFICAR: Permitirá modificar registros existentes.
   * ELIMINAR: Permitirá eliminar registros existentes.
   * BUSCAR: Permitirá buscar y mostrar registros exitentes.
   * ESTADOSIS: Muestra información de la base de datos.
   * OPTIMIZAR: Limpiará la base de datos de registros eliminados.
   * SALIR: Cierra el programa.
   * INDEF: Comando indefinido. Se utiliza para indicar errores.}
  TComandosSistema= (NUEVO,MODIFICAR,ELIMINAR,BUSCAR,ESTADOSIS,OPTIMIZAR,SALIR,INDEF);

  {Representa el registro de una persona en el sistema.}
  TRegistroPersona= packed record
     Id: int64;
     Nombre, Apellido: String[20];
     Documento: String[10];
     Edad, Peso: byte;
     Eliminado: boolean;
  end;

  {El archivo en el que se guardarán los datos.}
  TBaseDeDatos= file of TRegistroPersona;


var entradaEstandar, documentoAux: String;
    sysCom: TComandosSistema;
    objCom: TComando;
    archivoDataBase, archivoTempBase: TBaseDeDatos;
    registroPersona: TRegistroPersona;
    i, cantidadRegActivos, cantidadRegEliminados: int64;
    j:int64;

  {Recibe un comando c de tipo TComando y retorna su equivalente en
  TComandoSistema. Esta operación simplemente verifica que el nombre
  del comando c sea igual a alguna de las constantes COMANDO definidas
  en este archivo. Concretamente si:

  * El nombre de c es igual a COMANDO_NUEVO_TEXTO retorna TComandosSistema.NUEVO
  * El nombre de c es igual a COMANDO_MODIFICAR_TEXTO retorna TComandosSistema.MODIFICAR
  * El nombre de c es igual a COMANDO_ELIMINAR_TEXTO retorna TComandosSistema.ELIMINAR
  * El nombre de c es igual a COMANDO_BUSCAR_TEXTO retorna TComandosSistema.BUSCAR
  * El nombre de c es igual a COMANDO_ESTADOSIS_TEXTO retorna TComandosSistema.ESTADOSIS
  * El nombre de c es igual a COMANDO_OPTIMIZAR_TEXTO retorna TComandosSistema.OPTIMIZAR
  * El nombre de c es igual a COMANDO_SALIR_TEXTO retorna TComandosSistema.SALIR

  En cualquier otro caso retorna TComandosSistema.INDEF.}
  function comandoSistema(const c: TComando): TComandosSistema;
  begin
      if CompareText(nombreComando(c),COMANDO_NUEVO_TEXTO)=0 then
         result:= TComandosSistema.NUEVO
      else if CompareText(nombreComando(c),COMANDO_MODIFICAR_TEXTO)=0 then
         result:= TComandosSistema.MODIFICAR
      else if CompareText(nombreComando(c),COMANDO_ELIMINAR_TEXTO)=0 then
         result:= TComandosSistema.ELIMINAR
      else if CompareText(nombreComando(c),COMANDO_BUSCAR_TEXTO)=0 then
         result:= TComandosSistema.BUSCAR
      else if CompareText(nombreComando(c),COMANDO_ESTADOSIS_TEXTO)=0 then
         result:= TComandosSistema.ESTADOSIS
      else if CompareText(nombreComando(c),COMANDO_OPTIMIZAR_TEXTO)=0 then
         result:= TComandosSistema.OPTIMIZAR
      else if CompareText(nombreComando(c),COMANDO_SALIR_TEXTO)=0 then
         result:= TComandosSistema.SALIR
      else
         result:= TComandosSistema.INDEF;
  end;

  {Busca en el arhivo, un registro con el documento indicado y lo asigna a reg
  retornando TRUE. Si no existe en el archivo un registro con el documento indicado
  entonces retorna FALSE.}
  function buscarRegistro(documento: String; var reg: TRegistroPersona; var archivo: TBaseDeDatos): boolean;
  var
      i:int64;

  begin
      for i:=0 to FileSize(archivo)-1 do begin
        seek(archivo,i);
        read(archivo,reg);
        if compareStr(documento,reg.Documento)=0 then begin
           result:=true;
           exit;
        end;
      end;
      result:=false;
  end;

  {Retorna una línea de texto formada por 78 guiones}
  function stringSeparadorHorizontal(): String;
  var i: byte;
  begin
      result:= '';
      for i:=1 to 78 do
          result+= '-';
  end;

  {Retorna una línea de texto que forma el encabezado de la salida al imprimir
  los registros.}
  function stringEncabezado(): String;
  begin
      result:= Format(FORMAT_ID,[COLUMNA_ID])+'|'+Format(FORMAT_DOCUMENTO,[COLUMNA_DOCUMENTO])+'|'+Format(FORMAT_NOMBRE_APELLIDO,[COLUMNA_NOMBRE])+'|'+Format(FORMAT_NOMBRE_APELLIDO,[COLUMNA_APELLIDO])+'|'+Format(FORMAT_EDAD_PESO,[COLUMNA_EDAD])+'|'+Format(FORMAT_EDAD_PESO,[COLUMNA_PESO]);
  end;

  {Retorna una línea de texto formada por los datos del registro reg para que
  queden vistos en formato de columnas}
  function stringFilaRegistro(const reg: TRegistroPersona): String;
  begin
      result:= Format(FORMAT_ID,[IntToStr(reg.Id)])+'|'+
               Format(FORMAT_DOCUMENTO,[reg.Documento])+'|'+
               Format(FORMAT_NOMBRE_APELLIDO,[reg.Nombre])+'|'+
               Format(FORMAT_NOMBRE_APELLIDO,[reg.Apellido])+'|'+
               Format(FORMAT_EDAD_PESO,[Inttostr(reg.Edad)])+'|'+
               Format(FORMAT_EDAD_PESO,[Inttostr(reg.Peso)]);
  end;

(*============================================================================*)
(****************************** BLOQUE PRINCIPAL ******************************)
(*============================================================================*)
begin

  repeat
    write(PROMPT);
    readln(entradaEstandar);
    objCom:=crearComando(entradaEstandar);
    sysCom:=comandoSistema(objCom);
    case sysCom of
//NUEVO
         NUEVO:begin
            AssignFile(ArchivoDataBase,BASEDEDATOS_NOMBRE_REAL);
            if FileExists(BASEDEDATOS_NOMBRE_REAL) then
               reset(ArchivoDataBase)
            else
               rewrite(ArchivoDataBase);



            i:=FileSize(archivoDataBase);

            if cantidadParametros(objCom) <> 5 then begin
            writeln('ERROR: Cantidad de Parametros incorrecta:[DOCUMENTO,NOMBRE,APELLIDO,EDAD,PESO].');
            closeFile(archivoDataBase);
            continue;
            end;
            //Documento
            resetearParametros(objCom);
            siguienteParametro(objCom);

            //Encontrar alguna forma de hacer que me den la string
            entradaEstandar:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            if buscarRegistro(entradaEstandar,registroPersona,archivoDataBase) then begin
               write('ERROR: Ya existe un registro con documento '+registroPersona.Documento+': '+registroPersona.Nombre+' '+registroPersona.Apellido);
               closeFile(archivoDataBase);
               continue;
            end;
            registroPersona.Documento:=ObtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            //Nombre
            siguienteParametro(objCom);
            registroPersona.Nombre:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            //Apellido
            siguienteParametro(objCom);
            registroPersona.Apellido:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            //Edad
            siguienteParametro(objCom);
            if not obtenerNumero(registroPersona.Edad,objCom.listaParametros.argumentos[objCom.puntero]) then begin
               writeln('ERROR: El parametro EDAD debe ser un numero entero');
               closeFile(archivoDataBase);
               continue;
            end;
            //Peso
            siguienteParametro(objCom);
            if not obtenerNumero(registroPersona.Peso,objCom.listaParametros.argumentos[objCom.puntero]) then begin
               writeln('ERROR: El parametro PESO debe ser un numero entero');
               closeFile(archivoDataBase);
               continue;
            end;
            //id
            registroPersona.Id:=FileSize(archivoDataBase);
            //ELIMINADO
            registroPersona.Eliminado:=false;
            //Si todo sale bien recogemos los datos para subirlo a la base de datos
            seek(archivoDataBase,FileSize(archivoDataBase));
            write(archivoDataBase,registroPersona);
            CloseFile(archivoDataBase);
            //Se logro
            writeln('Registro agredado exitosamente');
         end;
//MODIFICAR
         MODIFICAR:begin
            AssignFile(ArchivoDataBase,BASEDEDATOS_NOMBRE_REAL);
            if FileExists(BASEDEDATOS_NOMBRE_REAL) then
               reset(ArchivoDataBase)
            else
                rewrite(ArchivoDataBase);
            //Si la cantidad de argumentos no es correcto sale sale error
            if cantidadParametros(objCom) <> 5 then begin
            writeln('ERROR: Cantidad de Parametros incorrecta: [DOC_ORIGINAL,NOMBRE,APELLIDO,EDAD,PESO].');
            closeFile(archivoDataBase);
            continue;
            end;
            // LUEGO SE VERIFICA SI EXISTE EL REGISTRO
            siguienteParametro(objCom);
            entradaEstandar:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            if NOT buscarRegistro(entradaEstandar,registroPersona,archivoDataBase) then begin
               write('ERROR: No existe un registro con documento '+ENTRADAESTANDAR+' para modificar ');
               closeFile(archivoDataBase);
               continue;
            end;
            //Nombre
            siguienteParametro(objCom);
            RegistroPersona.Nombre:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            //Apellido
            siguienteParametro(objCom);
            registroPersona.Apellido:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            //Edad
            siguienteParametro(objCom);
            if not obtenerNumero(registroPersona.Edad,objCom.listaParametros.argumentos[objCom.puntero]) then begin
               write('ERROR: El parametro EDAD debe ser un numero entero');
               closeFile(archivoDataBase);
               continue;
            end;
            //Peso
            siguienteParametro(objCom);
            if not obtenerNumero(registroPersona.Peso,objCom.listaParametros.argumentos[objCom.puntero]) then begin
               write('ERROR: El parametro PESO debe ser un numero entero');
               closeFile(archivoDataBase);
               continue;
            end;
            //id
            seek(archivoDataBase,registroPersona.Id);
            write(archivoDataBase,registroPersona);

            //Si todo va bien se termina
            writeln('Modificacion exitosa');
           closeFile(archivoDataBase);
         end;
//ELIMINAR
         ELIMINAR:begin
           AssignFile(ArchivoDataBase,BASEDEDATOS_NOMBRE_REAL);
            if FileExists(BASEDEDATOS_NOMBRE_REAL) then
               reset(ArchivoDataBase)
            else
                rewrite(ArchivoDataBase);
            //Verificamos la cantidad de argumentos recibidos
            if (cantidadParametros(objCom)<>1) and (cantidadParametros(objCom)<>2) then begin
               writeln('ERROR: Cantidad de parametros incorrecta: [-T] o [-D,DOCUMENTO]');
               closeFile(archivoDataBase);
               continue;
            end;

            //Verificamos si el primero argumeto es -T o -D
            siguienteParametro(objCom);
            entradaestandar:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
            if entradaEstandar = '-T' then begin
               //PONE EL VALOR EN TRUE

               for i:=0 to fileSize(archivoDataBase)-1 do begin
                  seek(archivoDataBase,i);
                  read(archivoDataBase,RegistroPersona);
                  registroPersona.Eliminado:=true;
                  seek(archivoDataBase,i);
                  write(archivoDataBase,registroPersona);
               end;

            end else if entradaEstandar = '-D' then begin
               //SOLO ELIMINA AL ELEGIDO
               siguienteParametro(objCom);
               entradaestandar:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
               if buscarRegistro(entradaEstandar,registroPersona,archivoDataBase) then begin
                  seek(archivoDataBase,registroPersona.Id);
                  read(archivoDataBase,registroPersona);
                  registroPersona.Eliminado:=true;
                  seek(archivoDataBase,registroPersona.Id);
                  write(archivoDataBase,registroPersona);
                  writeln('Registro Eliminado Exitosamente');
               end else begin
                  writeln('No existe un registro con documento '+entradaEstandar+' para modificar');
               end;
            end else begin
               writeln('El argumento no es correcto o faltan datos');
            end;
           CloseFile(archivoDataBase);
         end;
//BUSCAR
         BUSCAR:begin
           AssignFile(ArchivoDataBase,BASEDEDATOS_NOMBRE_REAL);
            if FileExists(BASEDEDATOS_NOMBRE_REAL) then
               reset(ArchivoDataBase)
            else
                rewrite(ArchivoDataBase);
            //todos los registros
           if cantidadParametros(objCom) = 0 then begin
              entradaEstandar:=stringEncabezado;
              writeln(entradaEstandar);
              entradaEstandar:=stringSeparadorHorizontal;
              writeln(entradaEstandar);
              i:=0;
              while not eof(archivoDataBase) do begin
                read(archivoDataBase,registroPersona);
                if not registroPersona.Eliminado then begin
                   entradaEstandar:=stringFilaRegistro(registroPersona);
                   writeln(entradaEstandar);
                   i+=1;
                end;
              end;
              writeln('Registros mostrados: ', i);


           end else if cantidadParametros(objCom) = 1 then begin
              siguienteparametro(objCom);

              entradaestandar:=obtenerString(objCom.listaParametros.argumentos[objCom.puntero]);
              if buscarRegistro(entradaEstandar,registroPersona,archivoDatabase) and not registroPersona.Eliminado then begin
                 entradaEstandar:=stringEncabezado;
                 writeln(entradaEstandar);
                 entradaEstandar:=stringSeparadorHorizontal;
                 writeln(entradaEstandar);
                 entradaEstandar:=stringFilaRegistro(registroPersona);
                 writeln(entradaEstandar);
              end else begin
                  writeln('No existe un registro con '+entradaEstandar+' [DOCUMENTO]');
              end;


           end else begin
             writeln('La cantidad de parametros es incorrecta: [] o [DOCUMENTO]');
           end;

           closeFile(archivoDataBase);
         end;
//ESTADOSIS
         ESTADOSIS: begin
           AssignFile(ArchivoDataBase,BASEDEDATOS_NOMBRE_REAL);
           if FileExists(BASEDEDATOS_NOMBRE_REAL) then
               reset(ArchivoDataBase)
           else
                rewrite(ArchivoDataBase);

           i:=0;

           while not eof(archivoDataBase) do begin
                read(archivoDataBase,registroPersona);
                if not registroPersona.Eliminado then begin
                   i+=1;
                end;
              end;

           writeln('Registros totales: ',filesize(archivoDataBase),' - Registros activos: ',i,' - Registros eliminados:',filesize(archivoDataBase)-i);

         closefile(archivodataBase);
         end;
//OPTIMIZAR
         OPTIMIZAR: begin
           //Abrir el archivo que estamos trabajando
           AssignFile(ArchivoDataBase,BASEDEDATOS_NOMBRE_REAL);
           if FileExists(BASEDEDATOS_NOMBRE_REAL) then
               reset(ArchivoDataBase)
           else
               rewrite(ArchivoDataBase);
           //Abrir el archivo temporal
           AssignFile(archivoTempBase,BASEDEDATOS_NOMBRE_TEMPORAL);
           if FileExists(BASEDEDATOS_NOMBRE_TEMPORAL) then
               reset(ArchivoTempBase)
           else
               rewrite(ArchivoTempBase);
           //INICIAMOS EL CONTADOR PARA EL NUEVO INDICE
           j:=-1;

           for i:=0 to fileSize(archivoDataBase)-1 do begin
             seek(archivoDataBase,i);
             read(archivoDataBase,registroPersona);
             If not registroPersona.Eliminado then begin
                j+=1;
                seek(archivoTempBase,j);
                registroPersona.Id:=j;
                write(archivoTempBase,registroPersona);
             end;
           end;

           closeFile(archivodataBase);
           Closefile(archivoTempBase);

           if deleteFile(BASEDEDATOS_NOMBRE_REAL) then begin
              renameFile(BASEDEDATOS_NOMBRE_TEMPORAL,BASEDEDATOS_NOMBRE_REAL);
              writeln('Base de datos OPTIMIZADA');
           end else begin
              deleteFile(BASEDEDATOS_NOMBRE_TEMPORAL);
              writeln('Ocurrio un Error al optimizar por favor reincie el programa');
           end;
         end;
         INDEF: begin
           writeln('ERROR: El comando ingresado no es correcto');
         end;
         SALIR:writeln('Nos vemos pronto');





    end;



  until sysCom=SALIR ;
  readln;

end.

