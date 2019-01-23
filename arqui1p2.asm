;------------------------------------------------------  Hola Mundo!! --------------------------------------------------
;El programa muestra en pantalla un saludo de Hola MUndo!
;Autor: Nelson Jair González
;Carnet: 200412956
;21/09/2015

;*************************************** MACROS ********************************************************
%macro  cambiar_modo_grafico 0
	push ax
	;mov ax,0013h  ----  modo grafico. 40x25. 256 colores. 320x200 pixeles. 1 pagina. 
	mov ax,0012h		;640 x 400
	int 10h
	pop ax
%endmacro

%macro  cambiar_modo_texto 0
	push ax
	;modo grafico. 40x25. 256 colores. 320x200 pixeles. 1 pagina. 
	mov ax,0003h
	int 10h
	pop ax
%endmacro

%macro set_fila_columna_color 3
	mov cl, %3  ;color
	mov dh, %1 ;fila
	mov dl,  %2	;columna
%endmacro

%macro preservar_registros 0
	push ax
	push bx
	push cx
	push dx	
	push di
	push si
%endmacro

%macro recuperar_registros 0
	pop si
	pop di
	pop dx
	pop cx
	pop bx 
	pop ax
%endmacro

%macro imprimir 1
		push ax		
		mov ah, 09
		mov dx, %1
		int 21h		
		pop ax
%endmacro

;Parámetros: 1=posX, 2=posY, 3= longitud,  4=ancho, 5=color
%macro  dibujar_linea_horizontal 5
		; se preservan valores de registros
		push ax
		push cx
		push dx
		;   INT 10h / AH = 0Ch - cambiar color de un pixel.
		;   AL = color
		;   CX = columna
		;   DX = fila			
		
		mov cx, %1
		mov dx, %2				
						
	%%pintaPixel:			
		mov ah, 0Ch 
		mov al, %5
		int 10h  	; se pinta el pixel
		
		inc dx		;se aumenta la fila (para ancho)
		mov ax, dx	
		sub ax, %2	;se resta la fila actual - posY inicial para obtener el ancho de la linea
		cmp ax, %4	;el ancho es igual  al solicitado?
		jne %%pintaPixel
		
		mov dx, %2 	;se devuelve el valor inicial de fila (para ancho)
		inc cx			; se incrementa la columna
		;se comprueba si se ha alcanzado la longitud deseada
		mov ax, cx	
		sub ax, %1	;se resta la columna actual - pos	X original para obtener la longitud de la linea
		cmp ax, %3	;el largo es igual  al solicitado?
		jne %%pintaPixel
		
		;se devuelven valores iniciales a registros
		pop dx
		pop cx
		pop ax
        
%endmacro

;Parámetros: 1=posX, 2=posY, 3= longitud,  4=ancho, 5=color
%macro  dibujar_linea_vertical 5
		dibujar_linea_horizontal %1, %2, %4, %3, %5        
%endmacro

;Parámetros: 1=posX, 2=posY, 3= longitud,  4=ancho, 5=color
%macro  dibujar_rectangulo 5
		dibujar_linea_horizontal %1, %2, %3, %4, %5        
%endmacro
		
%macro delay 1
	push si
	push di
	;delay
		mov si, %1
	%%delay1:
		dec si
		jz %%fin_delay
		mov di, %1
	%%delay2:
		dec di
		jz %%delay1
		jmp %%delay2
	%%fin_delay:
		pop di
		pop si
%endmacro

;************************************* CÓDIGO *****************************************
SEGMENT codigo  		;segmento que contiene codigo

  	..start: 
		
		mov  ax,data    ;Mueve la dirección del segmento de datos a AX
		mov  ds,ax  	;Se guarda la direccion del segmento de datos en el registro de segmento de datos DS -data segment-)
		mov  es,ax		;Se copia la direccion del segmento de datos en el registro de segmento extra ES)
		
		mov  ax,stack     ;Mueve la dirección del segmento de pila a AX 
		mov  ss,ax        ;Se guarda la direccion del segmento de pila en el registro de segmento de pila SS -stack segment-)
		mov  sp,stacktop  ;SP (registro de puntero) apunta a la cima de la pila
										
;====================================================================	
		
		call marcar_celdas_bloqueadas
		call marcar_celdas_items
		;jmp menu_juego
		; se recuperan los usuarios desde el archivo
		call recuperar_usuarios
	menu:		
		cambiar_modo_grafico
				
		set_fila_columna_color 1,15,3		
		mov di, strMenuTitulo
		call write_grafico
		
		set_fila_columna_color 2,1,3
		mov di, strMenuPrompt
		call write_grafico
		
		set_fila_columna_color 4,5,2
		mov di, strMenuIngresar
		call write_grafico
		
		set_fila_columna_color 5,5,2
		mov di, strMenuRegistrar
		call write_grafico
		
		set_fila_columna_color 6,5,2
		mov di, strMenuSalir
		call write_grafico
	
	leer_opcion:
		; esperar por tecla
		call read_char

		cmp al, 31h		;ingresar
		jne menu_registro
		
		call solicitar_datos_ingreso	
		;al = 1, login exitoso; al=0 loggin no exitoso
		cmp al, 0
		je menu
		call menu_juego
		jmp menu
			
	menu_registro:
		cmp al, 32h		;registrar	
		jne menu_salir
		
		call solicitar_datos_registro
		jmp menu
	
	menu_salir:	
		cmp al, 33h		;salir
		jne leer_opcion;
		
		cambiar_modo_texto
		call salir

;=====================================================================
; Función: Solicita datos de ingreso (la única forma de salir de este procedimiento es con un login correcto)
; retorna al = 1, login exitoso; al=0 loggin no exitoso
	solicitar_datos_ingreso:
		cambiar_modo_texto
		
		mov dx, strPromptUsuario
		call write
		call read_line
		
		;preservo el usuario en memoria
		mov si, dx				
		mov di, strUsuario
		call copiar_string
		
		;solicito que ingrese la constraseña 
	solicitar_password_ingreso:
		call saltar_linea
		mov dx, strPromptPassword
		call write
		call read_line
						
		;preservo la contraseña  en memoria
		mov si, dx						
		mov di, strPassword1		
		call copiar_string
				
		call saltar_linea
		;buscar el usuario entre los usuarios
		mov dx, strUsuario
		call buscar_usuario
				
		call saltar_linea
		cmp ax, 0
		je usuario_inexistente
				
		
		;ax contiene la clave registrada del usuario
		push ax ; la almaceno para poder ubicar el punteo máximo del usuario
		;se procede a comparar la con su clave registrada
		mov si, ax
		mov di, strPassword1
		mov cx, 5  ;las contraseñas miden 5
	ciclo_comprobacion_pass:
		mov ah, [si]
		mov al, [di]
		cmp ah, al
		jne clave_ingresada_no_coincide		
		inc si
		inc di
		dec cx
		jnz ciclo_comprobacion_pass
		mov al, [di]
		cmp al, '$'
		jne clave_ingresada_no_coincide
		;recuperar el punteo máximo del usuario
		pop si
		add si, 6	;en esa posicion empieza el punteo máximo		
		;mov word [ptrPunteoMaxUsuario], si
		call convertir_a_entero		;convierto a entero el punteo leido como cadena y se coloca en ax
				
		mov si, intPunteoMaximo
		mov [si], ax
				
		call saltar_linea
		mov dx, strBienvenido
		imprimir dx
		mov dx, strUsuario
		imprimir dx		
		call read_char
		mov al, 1
		ret
	
	clave_ingresada_no_coincide:
		pop ax ; se habia apilado la dirección del password
		mov dx, strErrorPasswordIncorrecto
		call writeln
		jmp solicitar_password_ingreso
		
	usuario_inexistente:
		call saltar_linea
		mov dx, strErrorUsuarioInexistente
		call writeln
		mov dx, strPrompRegistrar
		call writeln
			
		call read_char
		cmp al, 's'
		je solicitar_password_registro
		cmp al, 'S'
		je solicitar_password_registro
		;jmp menu
		mov al, 0
		ret

;=====================================================================
; Función : Muestra el menú del juego una vez se ha loggeado un usuario
; retorna AL = numero de opcion seleccionada
	menu_juego:		
		cambiar_modo_grafico
		set_fila_columna_color 1,15,3		
		mov di, strMenuTitulo
		call write_grafico
		
		set_fila_columna_color 2,1,3
		mov di, strMenuPrompt
		call write_grafico
		
		set_fila_columna_color 4,5,2
		mov di, strMenuIniciarJuego
		call write_grafico
		
		set_fila_columna_color 5,5,2
		mov di, strMenuVolverJuego
		call write_grafico				
		
		set_fila_columna_color 6,5,2
		mov di, strMenuLimpiarJuego
		call write_grafico
		
		set_fila_columna_color 7,5,2
		mov di, strMenuLogOut
		call write_grafico		
		
		;usuario-------
		set_fila_columna_color 3,60,9
		mov di, strLabelUsuario
		call write_grafico
		
		set_fila_columna_color 4,60,10
		mov di, strUsuario
		call write_grafico
		
		;puntaje máx-------
		set_fila_columna_color 6,60,9
		mov di, strLabelPuntajeMax
		call write_grafico
		
		mov di, intPunteoMaximo
		call punteo_a_cadena
		
		set_fila_columna_color 7,60,10
		mov di, strPunteo
		call write_grafico
		
	leer_tecla_menu_juego:
		call read_char		
		;en al está la opción seleccionada en el menu del juego
		cmp al, 31h; 1: Iniciar juego
		jne volver_al_juego
		
		cambiar_modo_grafico		
		call pintar_escenario
		call dibujar_items
		;pos inicial del pacman
		mov cx, 40
		mov dx, 40
		call iniciar_ciclo_juego
		jmp menu_juego
		
	volver_al_juego:
		cmp al, 32h ;volver al juego
		jne limpiar_juego
		
		cambiar_modo_grafico		
		call pintar_escenario
		call dibujar_items
		;recupera ultima pos del pacman
		mov ah, 0
		mov al, [intPosColumna]
		mov bx, 10
		mul bl
		add ax, 30
		mov cx, ax
		
		mov ah, 0
		mov al, [intPosFila]
		mov bx, 10
		mul bl
		add ax, 30
		mov dx, ax
		call iniciar_ciclo_juego
		jmp menu_juego
	
	limpiar_juego:
		cmp al, 33h	;limpiar juego
		jne logout					
		
		mov ax, [intPunteo]		
		mov bx, [intPunteoMaximo]		
		cmp ax, bx
		jna limpiar_var_juego
		mov word [intPunteoMaximo], ax
		
		
	limpiar_var_juego:
		mov word [intPunteo], 0		
		mov byte [intPosColumna], 1
		mov byte [intPosFila], 1
		mov byte [intPasos], -1
		mov byte [intSegundos], 0
		mov byte [intMinutos], 0
		mov byte [direccion], 'e'
		
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		
		mov bx, celdas
		mov si, 0
	ciclo_limpiar_juego:
		inc si
		cmp si, 1764
		je fin_ciclo_limpiar_juego
		mov byte [bx+si], '-'
		jmp ciclo_limpiar_juego
		
	fin_ciclo_limpiar_juego:
		call marcar_celdas_bloqueadas
		call marcar_celdas_items
		
		cambiar_modo_grafico		
		call pintar_escenario
		call dibujar_items
		;pos inicial del pacman
		mov cx, 40
		mov dx, 40
		call iniciar_ciclo_juego
		jmp menu_juego
		
	logout:
		cmp al, 34h	;logout
		jne leer_tecla_menu_juego	

		;actualizar punteo máximo
		mov ax, [intPunteo]		
		mov bx, [intPunteoMaximo]		
		cmp ax, bx
		jna limpiar_var_juego_usuario
		mov word [intPunteoMaximo], ax
		
	limpiar_var_juego_usuario:
		mov word [intPunteo], 0		
		mov byte [intPosColumna], 1
		mov byte [intPosFila], 1
		mov byte [intPasos], -1
		mov byte [intSegundos], 0
		mov byte [intMinutos], 0
		mov byte [direccion], 'e'
		
		;falta almacenar el punteo máximo si lo hubiera
		mov word [intPunteoMaximo], 0
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		
		mov bx, celdas
		mov si, 0
	ciclo_logout:
		inc si
		cmp si, 1764
		je fin_ciclo_logout
		mov byte [bx+si], '-'
		jmp ciclo_logout
		
	fin_ciclo_logout:
		call marcar_celdas_bloqueadas
		call marcar_celdas_items
				
	fin_menu_juego:
		ret							
;=====================================================================
; Función que busca un usuario entre los usuarios almacenados en memoria
; Parámetros: dx -usuario a buscar-
; Retorna ax = posición de memoria de la contraseña del usuario o AX = 0 si no se halla el usuario
; utiliza la var: strUsuarioTemp, bx
	buscar_usuario:
		mov si, strUsuarios
		mov di, strUsuarioTemp
		mov bx,0
	leer_caracter_usuarios:
		mov al, [si]
			
		cmp al, '@'  ;@ = fin de usuarios
		je	fin_buscar_usuario	
		cmp al, ';'		; = fin de campo
		je	fin_campo		
		cmp al, '$'		; = fin de registro
		je	fin_registro
		;cualquier otro caracter se copia en el usuario temporal
		mov [di], al
		inc si
		inc di
		jmp leer_caracter_usuarios
		
	fin_campo:
		mov ah, '$'
		mov [di], ah	;se agrega el fin de cadena a strUsuarioTemp
		
		inc si
		inc di		
		
		mov di, strUsuarioTemp
		cmp bx, 0		
		jne leer_caracter_usuarios	 ;finalizo el campo de contraseña
		push si
		mov si, dx
						
	ciclo_comp_usu:			
		mov al, [si]
		mov ah, [di]
		
		cmp al, 24h
		je fin_ciclo_comp_usu
		cmp ah, 24h
		je fin_ciclo_comp_usu
		
		cmp al, ah	
		jne usuario_no_hallado
		inc si
		inc di
		jmp ciclo_comp_usu
	
	fin_ciclo_comp_usu:
		cmp al, 24h
		je fin_ciclo_comp_usu_2
		jmp usuario_no_hallado
	fin_ciclo_comp_usu_2:	
		cmp ah, 24h				
		je usuario_hallado	

		pop si
		mov di, strUsuarioTemp
		mov bx, 1
		jmp leer_caracter_usuarios
		
	usuario_hallado:		
		pop ax		; se almacena la direccion de la contraseña en ax
		ret
		
	usuario_no_hallado:
		pop si
		mov di, strUsuarioTemp
		mov bx, 1
		jmp leer_caracter_usuarios
		
	fin_registro:
		inc si
		mov di, strUsuarioTemp
		mov bx, 0	
		jmp leer_caracter_usuarios
		
	fin_buscar_usuario:
		mov ax, 0
		ret
;=====================================================================
; Función que recupera los usuarios almacenados en el archivo de usuarios y los almacena en memoria
; Retorna: si: -cadena donde se almacenó los usuarios-
; Utiliza: ax, bx, cx, di, si strPassword2 (aqui se almacena el password del usuario)	
	recuperar_usuarios:
		;abrir archivo de usuarios		
		mov dx, strNombreArchivo
		
		mov ah,3dh 	;abrir archivo en modo de lectura
		mov al, 0100_0000b
		int 21h
		jc error_usuarios_abrir_archivo
		;ax  = handle
		;leer del archivo		
		mov bx, ax ;handle
		mov ah, 3fh		
		mov cx, 2000
		mov dx, strUsuarios ;donde se guardara el condenido del archivo
		int 21h
		jc error_usuarios_leer_archvo 
				
		;cerrar el archivo
		mov ah,3eh		
		int 21h
		jc error_usuarios_cerrar_archvo 
		
		mov si, strUsuarios
		ret
								
	error_usuarios_abrir_archivo:			
		call write_char
		mov dx, strErrorAbrirArchivo		
		call writeln
		jmp salir
		
	error_usuarios_leer_archvo:
		mov dx, strErrorLeerArchivo
		call writeln
		jmp salir
		
	error_usuarios_cerrar_archvo:
		mov dx, strErrorCerrarArchivo		
		call writeln
		jmp salir
		
;=====================================================================
; traspasa los usuarios almaceados en memoria leidos desde el archivo y los coloca en memoria pero normalizados
	normalizar_usuarios:
		;mov di, strUsuariosArchivo
		mov si, strUsuarios
		mov cx, 0 ;veces que se ha leído el $
		
		ret
;=====================================================================
; Solicita datos de registro
	solicitar_datos_registro:
		cambiar_modo_texto
		
	solicitar_nombre_registro:
		mov dx, strPromptUsuario
		call write
		call read_line
		
		;preservo el usuario en memoria
		mov si, dx				
		mov di, strUsuario
		call copiar_string
		
		;compruebo que el usuario no exista
		mov dx, strUsuario
		call buscar_usuario
		cmp ax, 0
		jne error_nombre_usuario
				
		;solicito que ingrese la constraseña 
	solicitar_password_registro:
		call saltar_linea
		mov dx, strPromptPassword
		call write
		call read_line
						
		;preservo la contraseña 1 en memoria
		mov si, dx						
		mov di, strPassword1		
		call copiar_string
				
		;compruebo la longitud de la contraseña = 5
		call saltar_linea
		mov di, strPassword1
		call longitud_cadena
		cmp cx, 5		
		jne error_longitud_password
						
		;solicito que se vuelva a ingresar la contraseña		
		call saltar_linea
		mov dx, strPromptRePassword
		call write
		call read_line
		
		;preservo la contraseña 2 en memoria
		mov si, dx				
		mov di, strPassword2
		call copiar_string
									
		call saltar_linea
		;comparo las 2 contraseñas
		mov si, strPassword1
		mov di, strPassword2
		mov cx, 5
	registro_ciclo_password:		
		cmp byte[si], '$'
		je error_passwords_diferentes
		cmp byte[di], '$'
		je error_passwords_diferentes
		mov ah, [di]
		cmp ah, [si]
		jne error_passwords_diferentes
		inc si
		inc di
		dec cx
		jnz registro_ciclo_password
		cmp byte[si], '$'
		jne error_passwords_diferentes
		cmp byte[di], '$'
		jne error_passwords_diferentes		
			
		
		;guardar datos del registro
		mov si, strUsuario
		mov di, strPtoComa
		mov dx, strRegistro
		call concatenar_cadenas
		
		mov si, strRegistro
		mov di, strPassword1
		mov dx, strRegistro
		call concatenar_cadenas
		
		mov si, strRegistro
		mov di, strPtoComa		
		call concatenar_cadenas
		
		mov si, strRegistro
		mov di, strCero		
		call concatenar_cadenas
		
		call saltar_linea
		call agregar_usuario_archivo
		
		mov dx, strRegistroExitoso
		imprimir dx
		
		; se recuperan los usuarios desde el archivo
		call recuperar_usuarios
		
		call read_char
		ret
		
	error_nombre_usuario:
		call saltar_linea
		mov dx, strErrorUsuarioYaExite
		call writeln
		jmp solicitar_nombre_registro
		
	error_longitud_password:		
		call saltar_linea
		mov dx, strErrorPasswordInvalido
		call writeln
		jmp solicitar_password_registro
		
	error_passwords_diferentes:
		call saltar_linea
		mov dx, strErrorPasswordsNoCoinciden
		call writeln
		jmp solicitar_password_registro
		
		
;=====================================================================
; Crea un archivo de texto nuevo
	crear_archivo:
		cambiar_modo_texto
		mov ah,3ch
		mov cx,00000000b
		mov dx,strNombreArchivo
		int 21h
		jc error_crear
		jmp salir
	error_crear:
		mov dx, strErrorAbrirArchivo
			call writeln
			jmp salir
			
;=====================================================================
;Guarda en el archivo  de usuarios la cadena almacenada en DX
;Parámetros: 
;DX-cadena a guardar-
;Registros utilizados: ax, bx, di

	agregar_usuario_archivo:
			;cambiar_modo_texto
			push dx
			;abrir el archivo
			mov dx, strNombreArchivo	
			mov ah,3dh
			mov al,1h ;Abrimos el archivo en modo de escritura			
			int 21h
			jc error_abrir ;Si hubo error
			mov bx,ax ; mover hadfile
			
			;se coloca el puntero en el final del archivo			
			xor cx, cx
			xor dx, dx
			mov ah, 42h
			mov al, 02h
			int 21h
			jc error_cursor
												
			;se escribe en el fichero
			mov ah,40h 	;función para escribir sobre el archivo
			pop dx
			mov di, dx
			call longitud_cadena	;se calcula la longitud de la cadena y se guarda en cx
			inc cx
			int 21h 
			jc error_escribir
			
			mov ah,3eh  ;Cierre de archivo
			int 21h
			jc error_cerrar				
			ret
		
		error_abrir:
			mov dx, strErrorAbrirArchivo
			call writeln
			pop ax
			call salir
			
		error_cursor:
			mov dx, strErrorCursorArchivo
			call writeln
			pop ax
			call salir
			
		error_escribir:
			mov dx, strErrorEscribirArchivo
			call writeln
			pop ax
			call salir
			
		error_cerrar:
			mov dx, strErrorCerrarArchivo
			call writeln
			pop ax
			call salir
;=====================================================================
;Imprime en modo gráfico una cadena terminada en $
;Parámetros: 
;DI -cadena a imprimir-
;DH -fila
;DX -columna
;SL  -atributos color y fondo-
	write_grafico:				
		mov al, [di]		;caracter a imprimir
		cmp al, 24h		;caracter de fin de cadena
		je fin_write_grafico
				
		mov ah, 2 		; necesario para cambiar la posición del cursor
		int 10h				;se ejecuta el posicionamiento del cursor		
		mov ah, 09h 	;necesario para imprimir un caracter en la pos actual del puntero		
		mov bh, 0			;numero de página
		mov bl, cl			;atributos color y fondo
		push cx
		mov cx, 1			;veces a imprimir
		int 10h				;se realiza la interrupcion que imprimirá el caracter
		pop cx			
		inc di				;se avanza al siguiente caracter de la cadena
		inc dl				;se corre el cursor una unidad a la derecha
		jmp write_grafico
	fin_write_grafico:		
		ret
		
		
;=====================================================================
; Procedimiento: Imprimie un caracter en pantalla
; Parámetros: AL
	write_char:
		push ax
		mov ah,	0x0E
		int 0x10	
		pop ax
		ret
;=====================================================================
;Imprime en pantalla una cadena terminada en $
;Parámetros: DX -cadena a imprimir-
	write:
		push ax		
		mov ah, 09
		int 21h		
		pop ax
		ret	
		
;=====================================================================
;Imprime en pantalla una cadena terminada en $ junto con un salto de línea
;Parámetros: DX -cadena a imprimir-
	writeln:
		call write
		call saltar_linea
		ret	
				
;=====================================================================
;Imprime en pantalla un salto de línea
	saltar_linea:
		push ax
		push dx
		mov dx, strSaltoLinea
		mov ah, 09
		int 21h
		pop dx
		pop ax
		ret	
		
;=====================================================================
;Función: obtiene el codigo ascii de la tecla presionada sin eco, via BIOS
;Destino: AL 
	read_char:	
		mov ah, 0 ;funcion 0h
		int 0x16	;de la interrupcion 16h
		ret
		
;=====================================================================
;Función: obtiene una cadena leida desde el teclado lóngitud máxima de 20 caracteres
;Destino: DX 
;utiliza: registros: ax, cx, di y la variable strLogitud20
	read_line:
		;limpiar la variable temporal que almacenará el string----
		mov cx, 20		
		mov di, strLogitud20
		call borrar_cadena
	read_line_ciclo:
		call read_char
		call write_char
		cmp al, 13 		;enter
		je fin_read_line
		mov [di], al
		dec cx
		cmp cx, 0
		je fin_read_line
		inc di
		jmp read_line_ciclo
	fin_read_line:
		mov dx, strLogitud20
		ret

;=====================================================================
;Función: calcula la longitud de una cadena terminada en $
;Destino: CX 
;Parámetros: DI -cadena-
	longitud_cadena:
		push di
		push ax
		mov cx, 0
	ciclo_longitud_cadena:
		mov al, [di]		
		cmp al, 24h		;caracter de fin de cadena
		je fin_longitud_cadena
		inc cx
		inc di
		jmp ciclo_longitud_cadena
	fin_longitud_cadena:
		pop ax
		pop di
		ret
		
;=====================================================================
;LLena un string con el caracter $
;parametros: 
;di -cadena a limpiar-
;cx -longitud de la cadena-
	borrar_cadena:	
		push cx
		push di				
	borrar_caracter:
		mov byte[di], '$'
		inc di
		dec cx		
		jg borrar_caracter
		pop di
		pop cx
		ret
		
;=====================================================================
;Copia una cadena almacenada en memoria en otra
;parametros: 
;si cadena origen
;di cadena destino
	copiar_string:
		call longitud_cadena ;calcula la longitud de la cadena destino
		call borrar_cadena 	;se limpia la cadena destino
		push di				
		mov di, si					
		call longitud_cadena	;se calcula cuantos caracteres se copiaran		
		pop di
		rep movsb		
		ret
		
;=====================================================================
;Función: Compara dos cadenas almacenada en memoria
;parametros: 
;si cadena1
;di cadena2
;Retorna: ax=0 si son iguales
;registros utilizados: ax, cx
	comparar_strings:		
		push di
		push si
		mov cx, 0
	comparar_caracter:
		mov ah, [si]
		mov al, [di]
		cmp ah, 24h  	;fin de cadena
		je comparar_longitud
		inc cx	
		cmp al, 24h
		je comparar_longitud				
		cmp ah, al
		jne fin_comparacion		
		inc si
		inc di				
		jmp comparar_caracter
	comparar_longitud:		
		pop si
		pop di
		push cx	;la longitud de c1 se almacena en pila
		call longitud_cadena		;se calcula la longitud de c2
		
		pop ax		;se recupera la longitud de c1		
		
		cmp ax, cx		
		je cadenas_iguales
		mov ax, 1
		jmp fin_comparacion
		
	cadenas_iguales:
		mov ax,0		
		
	fin_comparacion:				
		ret
		
		
;=====================================================================
;Función que concatena dos cadenas almacenadas en memoria (máximo tamaño al concatenar 50 caracteres)
;parámetros:
;si, di cadenas a concatenar en ese orden
;dx variable en la que se alamacenará el resultado de la concatenacion (al menos 50 caracteres)
;retorna dx: puntero a la cadena concatenada
;utiliza: ax, bx, variable strLogitud50
	concatenar_cadenas:		
		push di
		push si
		mov di, strLogitud50
		call copiar_string	
		pop di		
		call longitud_cadena		;cx almacena la longitud de la cadena1		
		mov bx, strLogitud50
		add	bx, cx
		pop di		
	concatenar_caracter:
		mov al, [di]
		cmp al, 24h
		je fin_concatenar
		mov [bx], al
		inc bx
		inc di
		jmp concatenar_caracter
	fin_concatenar:
		mov si, strLogitud50
		mov di, dx
		call copiar_string
		ret
		
;=====================================================================
;Función que convierte una cadena terminada en $ en un entero (máximo 4 caracteres)
;parámetros:
;si: cadana a convertir
;retorna: ax	numero entero en formato binario
	convertir_a_entero:	
		push si
		mov di, strPunteo		
		mov byte [di], 30h
		inc di
		mov byte [di], 30h
		inc di
		mov byte [di], 30h
		inc di
		mov byte [di], 30h
		
	leer_caracter_entero:
		mov al, [si]		
		cmp al, '$'
		je fin_leer_caracter_entero
		mov [di], al
		dec di
		inc si
		jmp leer_caracter_entero
		
	fin_leer_caracter_entero:		
		mov bx, 10	
		mov ax, 0
		mov cx, 0
		mov dx, 0
		mov di, strPunteo		
	conversion_entero_acumular:
		mov dl, [di]		
		sub dl, 30h
		push dx
		mul bx
		mov ax, dx
		pop dx
		add ax, dx
		inc di
		inc cx
		cmp cx, 4
		jne conversion_entero_acumular			
		pop si
		ret
	
;=====================================================================
;Procedimiento que grafica un rectangulo 
;parámetros:
;   CX = columna
;   DX = fila
;utiliza: di, si, ax, 				
	borrar_pacman:		
		mov al, 0
		jmp pintar_pacman
;=====================================================================
;Procedimiento que grafica un rectangulo 
;parámetros:
;   CX = columna
;   DX = fila
;utiliza: di, si, ax, 				
	dibujar_pacman:		
		mov al, 14
;=====================================================================
;Procedimiento que grafica un rectangulo 
;parámetros:
;   CX = columna
;   DX = fila
;	AL = color	
;utiliza: di, si, ax, 				
	pintar_pacman:	
		push cx
		push dx
		mov di, 10
		mov si, 10
		mov ah, 0Ch 		
	pinta_pixel_pacman:				
		int 10h  	; se pinta el pixel		
		inc dx
		dec di	
		cmp di,0
		jne pinta_pixel_pacman
		mov di, 10
		sub dx, 10
		inc cx
		dec si
		cmp si, 0
		jne pinta_pixel_pacman
		
		;comprobar si debe pintarse la boca del pacman
		mov ah, 0
		mov al, [intPosColumna]
		mov bl, [intPosFila]
		add al, bl		
		mov bl, 2
		div bl
		cmp ah, 0 ;par?
		jne fin_dibujar_pacman
				
		;pintar boca del pacman
		pop dx
		pop cx		
		push cx
		push dx
		;la combinación de cx y dx apunta a esquina sup izq del pacman
		;seleccionar donde va a ir la boca dependiendo de la dirección
		mov bl, [direccion]
		cmp bl, 'e'
		jne dibujar_boca_oeste
		add cx, 4
		add dx, 2
		jmp dibujar_boca_pacman
	
	dibujar_boca_oeste:
		cmp bl, 'o'
		jne dibujar_boca_norte		
		add dx, 2
		jmp dibujar_boca_pacman
	
	dibujar_boca_norte:
		cmp bl, 'n'
		jne dibujar_boca_sur
		add cx, 2		
		jmp dibujar_boca_pacman
		
	dibujar_boca_sur:
		add cx, 2
		add dx, 4
		
	dibujar_boca_pacman:
		mov di, 6
		mov si, 6
		mov ah, 0Ch 		
		mov al, 0
	pinta_pixel_boca_pacman:				
		int 10h  	; se pinta el pixel		
		inc dx
		dec di	
		cmp di,0
		jne pinta_pixel_boca_pacman
		mov di, 6
		sub dx, 6
		inc cx
		dec si
		cmp si, 0
		jne pinta_pixel_boca_pacman
	
	fin_dibujar_pacman:
		pop dx
		pop cx
		ret
;=====================================================================
;Procedimiento: bloquea las celdas indicadas de forma vertical
;Parámetros:
;ax : fila_inicial		
;dx: columna_inicial
;cx, cant de celdas a bloquear
	bloquear_celdas_verticalmente:
		mov di, celdas
		mov bx, 42 
		mul bl		;multiplico la fila x 40
		mov bx, dx
		add bx, ax		
	bloquear_celda_verticalmente:																
		mov byte [bx+di], 'b'			;y la seteo como bloqueada		
		add bx, 42	;incremento la fila
		dec cx	;decremento la cant de celdas a bloquear		
		jnz bloquear_celda_verticalmente	
		ret
		
;=====================================================================
;Procedimiento: bloquea las celdas indicadas de forma vertical
;Parámetros:
;ax : fila_inicial		
;dx: columna_inicial
;cx, cant de celdas a bloquear
	bloquear_celdas_horizontalmente:
		mov di, celdas
		mov bx, 42 
		mul bl		;multiplico la fila x 40
		mov bx, dx
		add bx, ax		
	bloquear_celda_horizontalmente:																
		mov byte [bx+di], 'b'			;y la seteo como bloqueada		
		inc bx	;incremento la columna
		dec cx	;decremento la cant de celdas a bloquear		
		jnz bloquear_celda_horizontalmente	
		ret
		
	;=====================================================================
;Procedimiento: marca las celdas indicadas de forma vertical con item
;Parámetros:
;ax : fila_inicial		
;dx: columna_inicial
;cx, cant de celdas a marcar
	poner_item_celdas_verticalmente:
		mov di, celdas
		mov bx, 42 
		mul bl		;multiplico la fila x 40
		mov bx, dx
		add bx, ax		
	poner_item_celda_verticalmente:																
		mov byte [bx+di], 'i'			;y la seteo con item		
		add bx, 42	;incremento la fila
		dec cx	;decremento la cant de celdas a bloquear		
		jnz poner_item_celda_verticalmente
		ret
		
;=====================================================================
;Procedimiento: marca las celdas indicadas de forma vertical con item
;Parámetros:
;ax : fila_inicial		
;dx: columna_inicial
;cx, cant de celdas a marcar
	poner_item_celdas_horizontalmente:
		mov di, celdas
		mov bx, 42 
		mul bl		;multiplico la fila x 40
		mov bx, dx
		add bx, ax		
	poner_item_celda_horizontalmente:																
		mov byte [bx+di], 'i'			;y la seteo con item	
		inc bx	;incremento la columna
		dec cx	;decremento la cant de celdas a bloquear		
		jnz poner_item_celda_horizontalmente	
		ret
;=====================================================================
;Procedimiento: dibuja los laberintos del juego
	pintar_escenario:
		dibujar_linea_horizontal 20, 1, 5,3,1
		dibujar_linea_horizontal 25, 1, 5,3,2
		dibujar_linea_horizontal 30, 1, 5,3,3
		dibujar_linea_horizontal 35, 1, 5,3,4
		dibujar_linea_horizontal 40, 1, 5,3,5
		dibujar_linea_horizontal 45, 1, 5,3,6
		dibujar_linea_horizontal 50, 1, 5,3,7
		dibujar_linea_horizontal 55, 1, 5,3,8
		dibujar_linea_horizontal 60, 1, 5,3,9
		dibujar_linea_horizontal 65, 1, 5,3,10
		
		dibujar_linea_horizontal 75, 1, 5,3,27
		dibujar_linea_horizontal 80, 1, 5,3,54
		dibujar_linea_horizontal 85, 1, 5,3,81
		dibujar_linea_horizontal 90, 1, 5,3,14
		dibujar_linea_horizontal 95, 1, 5,3,15
		dibujar_linea_horizontal 100, 1, 5,3,16
		dibujar_linea_horizontal 105, 1, 5,3,17
		dibujar_linea_horizontal 110, 1, 5,3,18
		dibujar_linea_horizontal 115, 1, 5,3,19
		dibujar_linea_horizontal 120, 1, 5,3,20
		
		;usuario-------
		set_fila_columna_color 3,60,9
		mov di, strLabelUsuario
		call write_grafico
		
		set_fila_columna_color 4,60,10
		mov di, strUsuario
		call write_grafico
		
		;puntaje máx-------
		set_fila_columna_color 6,60,9
		mov di, strLabelPuntajeMax
		call write_grafico
		
		mov di, intPunteoMaximo
		call punteo_a_cadena
		
		set_fila_columna_color 7,60,10
		mov di, strPunteo
		call write_grafico
		
		;punteo -----------
		set_fila_columna_color 9,60,9
		mov di, strLabelPuntaje
		call write_grafico
		
		mov di, intPunteo
		call punteo_a_cadena
		
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		
		;cronometro-----------
		
		set_fila_columna_color 12,60,9
		mov di, strLabelTiempo
		call write_grafico
				
		
		;Parámetros: 1=posX, 2=posY, 3= longitud,  4=ancho, 5=color				
		;marco
		dibujar_linea_horizontal 30, 30, 420, 10, 1
		
		dibujar_linea_vertical 30, 30, 420, 10, 1
		dibujar_linea_vertical 440, 30, 420, 10, 1
		
		dibujar_linea_vertical 30, 230, 20, 10, 0 ;para borrar parte de la linea ant
		dibujar_linea_vertical 440, 230, 20, 10, 0 ;para borrar parte de la linea ant
		
		dibujar_linea_horizontal 30, 440, 420, 10, 1
		
					
		;ax : fila_inicial		
;dx: columna_inicial
;cx, cant de celdas a bloquear				
		;entrada tunel izq
		dibujar_linea_horizontal 30, 250, 50, 10, 1
		dibujar_linea_horizontal 30, 220, 50, 10, 1
		
		;entrada tunel der
		dibujar_linea_horizontal 400, 250, 50, 10, 1
		dibujar_linea_horizontal 400, 220, 50, 10, 1
		
		;laberintos
		;cuadrado interno
		dibujar_linea_horizontal 190, 190, 40, 10, 1
		dibujar_linea_horizontal 250, 190, 40, 10, 1
		dibujar_linea_vertical 280, 190, 100, 10, 1
		dibujar_linea_horizontal 190, 280, 100, 10, 1
		dibujar_linea_vertical 190, 190, 100, 10, 1
		;L inferior izquierda
		dibujar_linea_vertical 80, 280, 100, 10, 1
		dibujar_linea_horizontal 80, 370, 100, 10, 1
		;L inferior derecha		
		dibujar_linea_vertical 390, 280, 100, 10, 1
		dibujar_linea_horizontal 300, 370, 100, 10, 1
		;L superior izquierda		
		dibujar_linea_vertical 80, 100, 100, 10, 1
		dibujar_linea_horizontal 80, 100, 100, 10, 1
		;L superior derecha		
		dibujar_linea_vertical 390, 100, 100, 10, 1
		dibujar_linea_horizontal 300, 100, 100, 10, 1
		;T inferior	
		dibujar_linea_vertical 230, 310, 100, 20, 1						
		dibujar_linea_horizontal 80, 400, 320, 20, 1	
		;T superior	
		dibujar_linea_vertical 230, 60, 100, 20, 1						
		dibujar_linea_horizontal 80, 60, 320, 20, 1	
		
		;I izquierda		
		dibujar_linea_vertical 130, 150, 200, 10, 1
		; I derecha		
		dibujar_linea_vertical 340, 150, 200, 10, 1
		ret

;=====================================================================
;Función que obtiene el estado de una celda
;Parámetros: cx = columna  ax= fila
;retorna: AL = caracter de estado de la celda
	get_celda:
				
		push bx		
		mov bx, 42
		mul bl			
		add ax, cx		
		mov si, celdas
		add si, ax		
		mov al, [si]
		pop bx				
		
		ret
		
;=====================================================================
;Procedimiento: Bloquea las celdas del escenario (sin dibujar las paredes)
	marcar_celdas_bloqueadas:
		;marco
		mov ax, 0
		mov dx, 0
		mov cx, 42
		call bloquear_celdas_horizontalmente
		mov ax, 0
		mov dx, 0
		mov cx, 20
		call bloquear_celdas_verticalmente
		mov ax, 0
		mov dx, 41
		mov cx, 20		
		call bloquear_celdas_verticalmente
		
		mov ax, 22
		mov dx, 0
		mov cx, 20
		call bloquear_celdas_verticalmente
		mov ax, 22
		mov dx, 41
		mov cx, 20		
		call bloquear_celdas_verticalmente
		
		
		mov ax, 41
		mov dx, 0
		mov cx, 42
		call bloquear_celdas_horizontalmente
								
		;tunel izquierdo
		mov ax, 22
		mov dx, 0
		mov cx, 5
		call bloquear_celdas_horizontalmente

		mov ax, 19
		mov dx, 0
		mov cx, 5
		call bloquear_celdas_horizontalmente	
		
		;tunel derecho
		mov ax, 19
		mov dx, 37
		mov cx, 5
		call bloquear_celdas_horizontalmente	
		
		mov ax, 22
		mov dx, 37
		mov cx, 5
		call bloquear_celdas_horizontalmente
		
		;laberintos
		;cuadrado interno
		mov ax, 16
		mov dx, 16
		mov cx, 4
		call bloquear_celdas_horizontalmente
		
		mov ax, 16
		mov dx, 22
		mov cx, 4
		call bloquear_celdas_horizontalmente
		
		mov ax, 16
		mov dx, 25
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		mov ax, 25
		mov dx, 16
		mov cx, 10
		call bloquear_celdas_horizontalmente
		
		mov ax, 16
		mov dx, 16
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		;L inferior izquierda
		mov ax, 25
		mov dx, 5
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		mov ax, 34
		mov dx, 5
		mov cx, 10
		call bloquear_celdas_horizontalmente
		
		;L inferior derecha
		mov ax, 25
		mov dx, 36
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		mov ax, 34
		mov dx, 27
		mov cx, 10
		call bloquear_celdas_horizontalmente
						
		;L superior izquierda
		mov ax, 7
		mov dx, 5
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		mov ax, 7
		mov dx, 5
		mov cx, 10
		call bloquear_celdas_horizontalmente
		
		;L superior derecha
		mov ax, 7
		mov dx, 36
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		mov ax, 7
		mov dx, 27
		mov cx, 10
		call bloquear_celdas_horizontalmente
		
		;T inferior
		mov ax, 28
		mov dx, 20
		mov cx, 10
		call bloquear_celdas_verticalmente
		mov ax, 28
		mov dx, 21
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		mov ax, 37
		mov dx, 5
		mov cx, 32
		call bloquear_celdas_horizontalmente
		mov ax, 38
		mov dx, 5
		mov cx, 32
		call bloquear_celdas_horizontalmente
		
		;T superior
		mov ax, 3
		mov dx, 20
		mov cx, 10
		call bloquear_celdas_verticalmente
		mov ax, 3
		mov dx, 21
		mov cx, 10
		call bloquear_celdas_verticalmente
		
		mov ax, 3
		mov dx, 5
		mov cx, 32
		call bloquear_celdas_horizontalmente
		mov ax, 4
		mov dx, 5
		mov cx, 32
		call bloquear_celdas_horizontalmente		
		
		;I izquierda
		mov ax, 12
		mov dx, 10
		mov cx, 20
		call bloquear_celdas_verticalmente
				
		; I derecha
		mov ax, 12
		mov dx, 31
		mov cx, 20
		call bloquear_celdas_verticalmente
		
		ret
		
		
;=====================================================================
;Procedimiento: Marca con items las celdas del escenario (sin dibujarlas)
	marcar_celdas_items:
		;vertical sup izq
		mov ax, 3
		mov dx, 2
		mov cx, 16
		call poner_item_celdas_verticalmente
		;vertical inf izq
		mov ax, 26
		mov dx, 2
		mov cx, 15
		call poner_item_celdas_verticalmente
		;vertical sup der
		mov ax, 3
		mov dx, 39
		mov cx, 16
		call poner_item_celdas_verticalmente
		;vertical inf izq
		mov ax, 26
		mov dx, 39
		mov cx, 15
		call poner_item_celdas_verticalmente
		;horizontal sup 
		mov ax, 1
		mov dx, 5
		mov cx, 32
		call poner_item_celdas_horizontalmente
		;horizontal inferior
		mov ax, 40
		mov dx, 5
		mov cx, 32
		call poner_item_celdas_horizontalmente
		;vertical interior 1
		mov ax, 9
		mov dx, 8
		mov cx, 24
		call poner_item_celdas_verticalmente
		;vertical interior 2
		mov ax, 13
		mov dx, 13
		mov cx, 18
		call poner_item_celdas_verticalmente
		;vertical interior 3
		mov ax, 13
		mov dx, 28
		mov cx, 18
		call poner_item_celdas_verticalmente
		;vertical interior 4
		mov ax, 9
		mov dx, 34
		mov cx, 24
		call poner_item_celdas_verticalmente
		;horizontal interior 1
		mov ax, 6
		mov dx, 5
		mov cx, 15
		call poner_item_celdas_horizontalmente
		
		;horizontal interior 2
		mov ax, 6
		mov dx, 22
		mov cx, 15
		call poner_item_celdas_horizontalmente
		
		;horizontal interior 3
		mov ax, 35
		mov dx, 5
		mov cx, 15
		call poner_item_celdas_horizontalmente
		
		;horizontal interior 4
		mov ax, 35
		mov dx, 22
		mov cx, 15
		call poner_item_celdas_horizontalmente
		ret
		
;=====================================================================
;Procedimiento: Dibuja los items de las celdas en el escenario
	dibujar_items:
		mov di, celdas
		mov bx, 1764	;cant de celdas
	dibujar_item:
		dec bx		
		jz fin_dibujar_items
		mov al, [bx + di]	;obtengo el contenido de la celda
		cmp al, 'i'	;compruebo que haya un item en la celda		
		jne dibujar_item
		
		push bx
		mov ax, bx
		mov bx, 42
		div bl
		mov dx, ax
		xor ah, ah ;preservo solo el cociente en ax		(fila)
		xor dl, dl ;preservo solo el residuo en dx			(columna)
		xchg dh, dl
		
		mov bx, 10
		mul bl
		add ax, 30
		push dx
		mov dx, ax	;fila (en pixeles)
		pop ax
		mul bl
		add ax, 30
		mov cx, ax  	;columna (en pixeles)
		mov al, 10 	;color verde
		add cx, 3; para que quede centrado en la celda
		add dx, 3
		;CX = columna
		;   DX = fila
		;	AL = color	
		mov ah, 0Ch 
		mov bx, 3
	pintar_pixel_item:
		int 10h 
		inc cx
		int 10h
		inc cx
		int 10h
		inc cx
		int 10h
		sub cx, 3
		inc dx
		dec bx
		jnz pintar_pixel_item
		pop bx
		jmp dibujar_item
	fin_dibujar_items:
		ret	
		
;=====================================================================
;Procedimiento: actualiza el cronométro del 
	actualizar_cronometro:
		push cx
		push dx
		
		;se comieron todos los items? si ya, entonces no hay que actualizar el cronometro
		call hay_items_disponibles
		cmp al, 1 
		jne no_modificar_tiempo
						
		;inc byte [intPasos]; pasos = 0 (iteraciones de este ciclo inicialmente = -1)
		;mov al, [intPasos]
		;cmp al, 6
		mov ah, 2Ch
		int 21h		;obtengo la hora del sistema
		;dh = seg , cl = min
		mov ch, dh ;cx = seg-min
		;recupero hora anterior
		mov dl, [intMinutosSistema]
		mov dh, [intSegundosSistema]
		cmp dx, cx 		
		je no_modificar_tiempo
		
		mov byte [intMinutosSistema], cl
		mov byte [intSegundosSistema], ch
		
		mov byte [intPasos], 0
		inc byte[intSegundos]
		mov al, [intSegundos]
		cmp al, 60
		jne no_modificar_tiempo
		inc byte[intMinutos]
		mov byte [intSegundos], 0		
	no_modificar_tiempo:
		;minutos
		mov di, intMinutos
		call tiempo_a_cadena
		set_fila_columna_color 13,60,10
		mov di, strTiempo
		call write_grafico
		;:
		set_fila_columna_color 13,62,10
		mov di, strDosPtos
		call write_grafico
		;segundos
		mov di, intSegundos
		call tiempo_a_cadena
		set_fila_columna_color 13,63,10
		mov di, strTiempo
		call write_grafico
		
	
		pop dx
		pop cx
		ret
		
		
;=====================================================================
;Procedimiento: CICLO PRINCIPAL DEL JUEGO
	iniciar_ciclo_juego:
		call dibujar_item_ya_presente
		call imprimir_cronometro
		call dibujar_pacman	
		call read_char		
		call actualizar_hora_sistema
		cmp al, 'm'
		jne comparar
		ret
	ciclo_juego:	
		;call actualizar_hora_sistema
		call activar_items_extra
		call actualizar_cronometro
		call dibujar_pacman	
		delay 405
	leer_tecla_juego:				
		mov ah,06h     			
		push dx
		mov dl, 0FFh
		int 21h       	;se lee una tecla sin detener la ejecución del programa
		pop dx
			   
		jnz comparar
		mov al, [charTemp]
		
	comparar:			
		cmp al, 'd'
		jne izq	
		mov byte [direccion], 'e'
		mov [charTemp], al
		
		;comprobar que el movimiento sea valido		
		push cx				
		mov ax, 0		
		mov al, [intPosFila]	
		mov cx, 0		
		mov cl, [intPosColumna]
		add cl, 1
		call get_celda							
		pop cx		
		
		cmp byte [intPosColumna], 41
		je no_puntear_der
		
		cmp al, 'b'
		je ciclo_juego
							
		;se comió un item?
		cmp al, 'i'
		jne fresa_derecha
		;eliminar el item de la celda
		mov byte [si], '-'
		push cx
		push dx
		mov di, intPunteo
		inc word [di] 
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_der
		;----------------
		;se halló una fresa
	fresa_derecha:
		cmp al, 'f'
		jne cereza_derecha
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 15
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_der
		;----------------
		
		;se halló una cereza
	cereza_derecha:
		cmp al, 'c'
		jne naranja_derecha
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 25
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_der
		
		;se halló una naranja
	naranja_derecha:
		cmp al, 'n'
		jne no_puntear_der
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 5
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx		
		;----------------
				
	no_puntear_der:						
		call borrar_pacman
		add cx, 10
		inc byte [intPosColumna]
		cmp byte [intPosColumna], 42
		jne ciclo_juego
		mov cx, 30
		mov byte [intPosColumna], 0
		jmp ciclo_juego
	izq:
		cmp al, 'a'
		jne arr		
		mov [charTemp], al
		mov byte [direccion], 'o'
		;comprobar que el movimiento sea valido		
		push cx				
		mov ax, 0		
		mov al, [intPosFila]	
		mov cx, 0		
		mov cl, [intPosColumna]
		dec cl
		call get_celda							
		pop cx		
		cmp al, 'b'
		je ciclo_juego
		
		;se comió un item?
		cmp al, 'i'
		jne fresa_izquierda
		;eliminar el item de la celda
		mov byte [si], '-'
		push cx
		push dx
		mov di, intPunteo
		inc word [di] 
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_izq
		;----------------	
			;se halló una fresa
	fresa_izquierda:
		cmp al, 'f'
		jne cereza_izquierda
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 15
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_izq
		;se halló una cereza
	cereza_izquierda:
		cmp al, 'c'
		jne naranja_izquierda
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 25
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_izq
		
		;se halló una naranja
	naranja_izquierda:
		cmp al, 'n'
		jne no_puntear_izq
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 5
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx		
		;----------------
				
	no_puntear_izq:
					
		call borrar_pacman
		sub cx, 10
		dec byte [intPosColumna]
		cmp byte [intPosColumna], -1
		jne ciclo_juego
		mov cx, 440
		mov byte [intPosColumna], 41
		jmp ciclo_juego
	arr:
		cmp al, 'w'
		jne aba		
		mov [charTemp], al
		mov byte [direccion], 'n'
		;comprobar que el movimiento sea valido		
		push cx				
		mov ax, 0		
		mov al, [intPosFila]	
		mov cx, 0		
		mov cl, [intPosColumna]
		dec al
		call get_celda							
		pop cx		
		cmp al, 'b'
		je ciclo_juego
		
		;se comió un item?
		cmp al, 'i'
		jne fresa_arriba
		;eliminar el item de la celda
		mov byte [si], '-'
		push cx
		push dx
		mov di, intPunteo
		inc word [di] 
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_arr
		;----------------
		;se halló una fresa
	fresa_arriba:
		cmp al, 'f'
		jne cereza_arriba
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 15
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_arr
		;----------------
		
		;se halló una cereza
	cereza_arriba:
		cmp al, 'c'
		jne naranja_arriba
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 25
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_arr
		
		;se halló una naranja
	naranja_arriba:
		cmp al, 'n'
		jne no_puntear_arr
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 5
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx		
		;----------------
		
	no_puntear_arr:				
		call borrar_pacman
		sub dx, 10
		dec byte [intPosFila]
		jmp ciclo_juego
	aba:
		cmp al, 's'
		jne fin_ciclo_juego	
		mov [charTemp], al
		mov byte [direccion], 's'
		;comprobar que el movimiento sea valido		
		;comprobar que el movimiento sea valido		
		push cx				
		mov ax, 0		
		mov al, [intPosFila]	
		mov cx, 0		
		mov cl, [intPosColumna]
		add al, 1
		call get_celda							
		pop cx		
		cmp al, 'b'
		je ciclo_juego
		
		;se comió un item?
		cmp al, 'i'
		jne fresa_abajo
		;eliminar el item de la celda
		mov byte [si], '-'
		push cx
		push dx
		mov di, intPunteo
		inc word [di] 
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_aba
		;----------------
		;se halló una fresa
	fresa_abajo:
		cmp al, 'f'
		jne cereza_abajo
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 15
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_aba
		;----------------
		
		;se halló una cereza
	cereza_abajo:
		cmp al, 'c'
		jne naranja_abajo
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 25
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx
		jmp no_puntear_aba
		
		;se halló una naranja
	naranja_abajo:
		cmp al, 'n'
		jne no_puntear_aba
		;eliminar el item de la celda
		mov byte [si], '-'	
		mov byte [intFilaItemExtra], 0
		mov byte [intColumnaItemExtra], 0
		push cx
		push dx
		mov di, intPunteo
		add word [di], 5
		call punteo_a_cadena
		set_fila_columna_color 10,60,10
		mov di, strPunteo
		call write_grafico
		pop dx
		pop cx		
		;----------------
		
	no_puntear_aba:	
		call borrar_pacman
		add dx, 10
		inc byte [intPosFila]
		jmp ciclo_juego
	
	fin_ciclo_juego:
		cmp al, 'm'
		jne ciclo_juego
		ret
		
;=====================================================================
;Procedimiento que convierte a string el punteo (entero) y lo almacena en memoria
;Parámetros. di (punteo entero)
;retorna strPunteo
	punteo_a_cadena:
		push ax
		push bx
		push dx		
		push si
		
		mov si, strPunteo
		mov al,[di] 
		mov ah,[di+1] 
		
		mov dx,0 ;necesario para hacer la división de 2 bytes
		mov bx, 1000
		div bx		
		add al, 30h
		mov [si], al
				
		mov ax, dx
		mov dx,0 
		mov bx, 100
		div bx		
		add al, 30h
		mov [si+1], al
		;sub dl, 30h
		
		mov ax, dx
		mov dx,0 
		mov bx, 10
		div bx		
		add al, 30h
		mov [si+2], al
		;sub dl, 30h
		
		add dl, 30h
		mov [si+3], dl
						
		pop si
		pop dx
		pop bx
		pop ax
		ret
		
;=====================================================================
;Procedimiento que convierte en cadena el tiempo (minutos o segundos)
;Parámetros. di (tiempo entero 1 byte)
;retorna strTiempo
tiempo_a_cadena:
		push ax
		push bx
		push dx		
		push si
		
		mov si, strTiempo
		mov al,[di] 
		mov ah,0 				
		mov bx, 10
		div bl		
		
		add al, 30h
		mov [si], al
				
		xchg ah, al		
		add al, 30h
		mov [si+1], al
		;sub dl, 30h
		pop si
		pop dx
		pop bx
		pop ax
		ret
		
;=====================================================================
;Función que indica si todavía hay algún item que no haya sido devorado XD
;retorna al = 0 : no, al = 1 :sí
	hay_items_disponibles:
		push bx
		push si		
		mov al, 0
		mov bx, celdas		
		mov si, 0
		
	ciclo_busqueda_items:
		inc si
		cmp si, 1764
		je fin_busqueda_items
		
		mov ah, [bx+si]		
		cmp ah, 'i'
		jne ciclo_busqueda_items
		mov al, 1		
	fin_busqueda_items:				
		pop si
		pop bx
		ret
		
;=====================================================================
;Función que indica si todavía hay algún item extra que no haya sido devorado XD
;retorna al = 0 : no, al = 1: sí hay. 
	buscar_items_extra_disponibles:
		push bx
		push si		
		mov al, 0
		mov bx, celdas		
		mov si, 0
		
	ciclo_busqueda_items_extra:
		inc si
		cmp si, 1764
		je fin_busqueda_items_extra
		
		mov ah, [bx+si]		
		cmp ah, 'f'
		jne buscar_cereza
		mov al, 1
		jmp fin_busqueda_items_extra
	buscar_cereza:
		cmp ah, 'c'
		jne buscar_naranja
		mov al, 1		
		jmp fin_busqueda_items_extra
	buscar_naranja:
		cmp ah, 'n'
		jne ciclo_busqueda_items_extra
		mov al, 1
	fin_busqueda_items_extra:				
		pop si
		pop bx
		ret

;=====================================================================
;Procedimiento que elimina un item extra de memoria y pantalla solo si intFilaItemExtra y intColumnaItemExtra no son 0
	eliminar_items_extra:
		push ax
		push bx
		push cx 
		push dx
		push si
		;eliminar de pantalla
		mov cx, 0
		mov cl, [intColumnaItemExtra]
		mov dx, 0
		mov dl, [intFilaItemExtra]
		
		mov ax, cx
		add ax, dx
		jz fin_eliminar_items_extra
		push cx
		push dx
		
		mov al, 0
		call dibujar_item_extra
		;eliminar de memoria
		pop dx
		pop cx
		mov ax, dx
		mov bx, 42
		mul bl
		add ax, cx
		mov bx, ax
		mov si, celdas
		mov byte [bx + si], '-'
		
		mov byte [intColumnaItemExtra], 0
		mov byte [intFilaItemExtra], 0	
	fin_eliminar_items_extra:		
		pop si
		pop dx
		pop cx
		pop bx
		pop ax
		ret
		
;=====================================================================
;Procedimiento que, en base a la hora del sistema puede o no activar items extra
	activar_items_extra:	
		push ax
		push bx
		push cx
		push dx
		push si
		
		;compruebo si todavia hay items normales en pantalla
		call hay_items_disponibles
		cmp al, 0
		je fin_activar_item_extra_eliminando_extras
		;compruebo si ya hay un item en la pantalla
		call buscar_items_extra_disponibles
		cmp al, 0
		jne fin_activar_item_extra
		
		mov ah, 2Ch
		int 21h		;obtengo la hora del sistema
		mov cx, 0
		mov cl, dh ;preservo los segundos
		mov ax, cx
		mov bl, 2
		div bl
		mov cl, al 	;cx = columna donde aparecerá el item
		add cl, 1
		mov ax, 0
		mov al, dh
		mov bl, 5
		div bl		
		cmp ah, 0 ;segundos son multiplo de 5
		jne fin_activar_item_extra
		
		cmp dl, 35 ;centesimas
		ja fin_activar_item_extra
						
		mov dh, 0		;dl = fila donde aparecerá el item
		add dl, 1
		
		
		;comprobar que la celda no esté ocupada
		mov ax, dx ;ax = fila
		call get_celda
		cmp al, '-'
		jne fin_activar_item_extra
		;si apunta a la posición en memoria de la celda debido a la llamada a get_celda
		
		mov [intFilaItemExtra], dl
		mov [intColumnaItemExtra], cl
	seleccion_item_extra:
		;seleccion de item a agregar
		cmp cl, 12
		ja	agregar_fresa
		;naranja
		mov byte [si], 'n'
		mov al, 6
		mov [intColorItemExtra], al
		call dibujar_item_extra
		jmp fin_activar_item_extra
	agregar_fresa:
		cmp cl, 24
		ja	agregar_cereza
		;fresa
		mov byte [si], 'f'
		mov al, 4
		mov [intColorItemExtra], al
		call dibujar_item_extra
		jmp fin_activar_item_extra
	agregar_cereza:
		;cereza
		mov byte [si], 'c'
		mov al, 5
		mov [intColorItemExtra], al
		call dibujar_item_extra
		jmp fin_activar_item_extra
		
	fin_activar_item_extra_eliminando_extras:
		call eliminar_items_extra
	fin_activar_item_extra:
		pop si
		pop dx
		pop cx
		pop bx
		pop ax
		ret

;=====================================================================
;procedimiento que dibuja un item extra 
;parametros: al = color, cx=columna, dx = fila
	dibujar_item_extra:
		push si
		push di
		push bx
		mov si, 10
		mov di, 10
		
		push ax ;preservo el color
		mov ax, cx
		mov bl, 10
		mul bl
		add ax, 30
		mov cx, ax	;obtengo la columna en pixeles
		
		mov ax, dx
		mov bl, 10
		mul bl
		add ax, 30
		mov dx, ax	;obtengo la fila en pixeles
		pop ax ;recupero el color
		
		mov ah, 0Ch 		
	pinta_pixel_item_extra:				
		int 10h  	; se pinta el pixel		
		inc dx
		dec di	
		cmp di,0
		jne pinta_pixel_item_extra
		mov di, 10
		sub dx, 10
		inc cx
		dec si
		cmp si, 0
		jne pinta_pixel_item_extra
		
		pop bx
		pop di
		pop si
		ret

;=====================================================================
;función: actualiza hora del sistema 
;retorna : intSegundosSistema, intMinutosSistema
	actualizar_hora_sistema:
		push ax 
		push cx 
		push dx 
		mov ah, 2Ch
		int 21h		;obtengo la hora del sistema
		;dh = seg , cl = min
		mov byte [intSegundosSistema], dh
		mov byte [intMinutosSistema], cl 
		pop dx 
		pop cx 
		pop ax 
		ret
;=====================================================================
;Procedimiento: invocado después de que el usuario vuelve al juego luego de dar pausa
	dibujar_item_ya_presente:
		push ax
		push bx
		push cx
		push dx
		push si
		
		mov cx, [intColumnaItemExtra]
		mov dx, [intFilaItemExtra]		
				
		mov ax, dx
		add ax, dx
		jz fin_dibujar_item_ya_presente
				
		mov al, [intColorItemExtra]
		call dibujar_item_extra
		
	fin_dibujar_item_ya_presente:
		pop si
		pop dx
		pop cx
		pop bx
		pop ax
		ret

;=====================================================================
;Muestra el cronometro con los valores almacenados en memoria intSegundos, intMinutos
	imprimir_cronometro:
		push cx 
		push dx 
		;minutos
		mov di, intMinutos
		call tiempo_a_cadena
		set_fila_columna_color 13,60,10
		mov di, strTiempo
		call write_grafico
		;:
		set_fila_columna_color 13,62,10
		mov di, strDosPtos
		call write_grafico
		;segundos
		mov di, intSegundos
		call tiempo_a_cadena
		set_fila_columna_color 13,63,10
		mov di, strTiempo
		call write_grafico
		pop dx 
		pop cx 
		ret 

;=====================================================================
;Finaliza el programa correctamente
	salir:
		mov ah, 4Ch 
		int 21h
		
;************************************  DATOS ********************************************
;Segmento de datos inicializados	

SEGMENT data	
	strNombreArchivo DB 'USUARIOS.TXT',0	
	strNombreArchivo2 DB 'USUARIOS.txt',0	
	strErrorAbrirArchivo DB 'error al abrir el archivo$'
	strErrorCursorArchivo DB 'error al cambiar de posicion el cursor del archivo$'
	strErrorEscribirArchivo DB 'error al escribir el archivo$'
	strErrorCerrarArchivo DB 'error al cerrar el archivo$'
	strErrorLeerArchivo DB 'error al leer el archivo$'
	strSaltoLinea DB 10, 13, '$'
	strMenuTitulo DB 'PACMAN-MENU$'
	strMenuPrompt DB 'Elija una opcion:$'
	strMenuIngresar DB '1. Ingresar$'
	strMenuRegistrar DB '2. Registrarse$'
	strMenuSalir DB '3. Salir$'	
	strPromptUsuario DB 'Ingrese el nombre de usuario: $'	
	strPromptPassword DB 'Ingrese la clave: $'
	strPromptRePassword DB 'Vuelva a ingresar la clave: $'
	strErrorPasswordInvalido DB 'La clave ingresada debe tener 5 caracteres$'
	strErrorPasswordsNoCoinciden DB 'Las claves ingresadas no coinciden$'
	strErrorUsuarioYaExite DB 'El nombre de usuario ingresado ya esta en uso$'
	strRegistroExitoso DB 'Se ha registrado correctamente$'
	strErrorUsuarioInexistente DB 'El nombre de usuario ingresado no esta registrado$'
	strErrorPasswordIncorrecto DB 'La clave ingresada no es la correcta$'
	strPrompRegistrar DB 'Desea registrarse con el nombre de usuario ingresado? (S/N)$'
	strBienvenido DB 'BIENVENIDO $'
	strMenuIniciarJuego DB '1. Iniciar juego$'
	strMenuVolverJuego 	DB '2. Volver al juego$'
	strMenuLimpiarJuego DB '3. Limpiar juego$'
	strMenuLogOut DB '4. Logout$'
	strLabelUsuario DB 'Usuario:$'
	strLabelPuntaje DB 'Puntaje:$'
	strLabelPuntajeMax DB 'Puntaje max:$'
	strLabelTiempo DB 'Tiempo:$'
	strUsuario times 21 DB '$'
	strUsuarioTemp times 21 DB '$'
	strPassword1 times 6 DB '$'
	strPassword2 times 6 DB '$'	
	strLogitud20 times 21 DB '$'
	strLogitud50 times 51 DB '$'
	strRegistro times 51 DB '$'
	strPtoComa DB ';$'
	strCero	DB '0$'
	strPunteo DB '0000$'
	strTiempo DB '00$'
	strDosPtos DB ':$'
	intPunteoMaximo DW 0,0
	intPunteo DW 0,0	
	intDigit DB 0,'$'	
	intColorItemExtra DB 0
	intAltura DW 0,0
	intLongitud DW 0,0
	intPosFila DB 1
	intPosColumna DB 1
	intPasos DB -1
	intSegundos DB 0
	intMinutos DB 0
	intSegundosSistema DB 0
	intMinutosSistema DB 0
	charTemp DB 'k'
	direccion DB 'e' 	;e=este-o=oeste-n=norte-s=sur	
	intFilaItemExtra DB 0
	intColumnaItemExtra DB 0
	ptrPunteoMaxUsuario DW 0,0
	celdas times 1764 DB '-'
	;strUsuariosArchivo times 2001 DB '@'	;contendrá el contenido del archivo de usuarios
	strUsuarios times 2001 DB '@'	;contendrá a los usuarios 
	
;************************************  PILA  ********************************************
SEGMENT stack stack 	; Segmento de pila
	resb 1024      		; Se reservan 64 bytes para la pila del programa
    stacktop:          	; Esta etiqueta apunta al ultimo de los bytes reservados

