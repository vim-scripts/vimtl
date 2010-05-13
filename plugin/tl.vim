if has('python')
python << EOF
# -*- encoding: utf-8 -*-
import vim
import re
import string
 
DEFAULT_MARK = '☐'
MARKS = ['☐', '☑', '[_]', '[?]', '✕', '✔', '_ ', '[X]', '☒']
INDENT_WIDTH = 2
TO_DONE_DICT = {
                '☐': '☑', 
                '☒': '☑',
                '_ ': '✔ ',
                '✕ ': '✔ ',
                '[_]': '[X]',
                '[?]': '[X]',
               }
TO_EMPTY_DICT = {
                 '☑': '☐', 
                 '☒': '☐',
                 '✔': '_',
                 '✕': '_',
                 '[X]': '[_]',
                 '[?]': '[_]',
                }
TO_CANCEL_DICT = {
                '☐': '☒', 
                '☑': '☒',
                '_ ': '✕ ',
                '✔': '✕',
                '[_]': '[?]',
                '[X]': '[?]',
               }

TO_OTL = {
        '☐': '[_]',
        '☒': '[?]',
        '☑': '[X]',
        '✔': '[X]',
        '✕': '[?]',
        '_ ': '[_] ',
}

TO_BOX = {
        '✔': '☑',
        '✕': '☒',
        '_ ': '☐ ',
        '[_]': '☐',
        '[?]': '☒',
        '[X]': '☑',
}

TO_SINGLE = {
        '☐': '_',
        '☒': '✕',
        '☑': '✔',
        '[_]': '_',
        '[?]': '✕',
        '[X]': '✔',
}

def detectMarkStyle():
    # Explora las primeras 10 lineas del buffer
    # para determinar el caracter de casilla que se
    # utiliza en el documento.
    for line in vim.current.buffer:
        if have_any_of_this_charactes(line, ['[_]', '[X]']):
            ChangeDefaultMark('[_]')
            return
        elif have_any_of_this_charactes(line, ['☐', '☑']):
            ChangeDefaultMark('☐')
            return

def replace_all(text, dic):
    """Reemplaza varias palabras de una cadena:

        >>> replace_all("Hola mundo", {'Hola': 'chau', 'do': 'dos'})
        >>> 'chau mundos'
    """
    for i, j in dic.iteritems():
        text = text.replace(i, j)
    return text

def have_any_of_this_charactes(string, words):
    """Indica si una linea de texto contiene algunas palabras particulares::

        >>> have_any_of_this_charactes("a bb ccc", ['a'])
        >>> True
    """
    for w in words:
        if w in string:
            return True

def MarkDone():
    vim.current.line = replace_all(vim.current.line, TO_DONE_DICT)

def MarkCancel():
    vim.current.line = replace_all(vim.current.line, TO_CANCEL_DICT)

def CreateTask():
    "Genera una nueva tarea sobre la linea actual."
    line = vim.current.line

    if have_any_of_this_charactes(line, MARKS):
        new_line = replace_all(line, TO_EMPTY_DICT)
    else:
        if re.match("(\S+)", line):
            new_line = re.sub("(\S+)", "%s \\1" %(DEFAULT_MARK), line, count=1)
        elif re.match("^(\s+)", line):
            new_line = re.sub("^(\s+)", "\\1%s " %(DEFAULT_MARK), line, count=1)
        else:
            new_line = DEFAULT_MARK + " "

    vim.current.line = new_line

def tlConvertToOTL():
    "Convierte todas las casillas de tarea al formato de vimoutliner"
    size = len(vim.current.buffer)

    for i in range(0, size):
        vim.current.buffer[i] = replace_all(vim.current.buffer[i], TO_OTL)
    
    ChangeDefaultMark('[_]')

def tlConvertToBOX():
    "Convierte todas las casillas estilo vimoutliner al formato de cajas UTF8"
    size = len(vim.current.buffer)

    for i in range(0, size):
        vim.current.buffer[i] = replace_all(vim.current.buffer[i], TO_BOX)

    ChangeDefaultMark('☐')

def tlConvertToSingle():
    "Convierte todas las casillas estilo vimoutliner al formato simple"
    size = len(vim.current.buffer)

    for i in range(0, size):
        vim.current.buffer[i] = replace_all(vim.current.buffer[i], TO_SINGLE)

    ChangeDefaultMark('_')

def has_a_task_mark_in_this_line():
    "Indica si la linea actual tiene una casilla de tarea."
    for x in MARKS:
        if x in vim.current.line:
            return True


def CreateTaskIndent(extra_indent=0):
    "Genera una tarea en el mismo nivel de indentacion que la linea actual."

    # Genera la identacion de espacios que se le pida.
    indent = " " * INDENT_WIDTH * extra_indent

    if has_a_task_mark_in_this_line():
        # Copia la linea actual para preservar la identación.
        vim.command("normal yyp")

        # Preserva la identación y coloca la marca de tarea sin texto.
        vim.current.line = re.sub("\S.*", indent + DEFAULT_MARK + " ", vim.current.line)
    else:
        # Si la linea actual no tiene marcas entonces genera una marca a derecha
        # de los espacios iniciales.
        CreateTask()


def CreateSubTask():
    "Genera una subtarea en base a la que se encuentra mas arriba."
    CreateTaskIndent(1)

def ChangeDefaultMark(new_mark):
    global DEFAULT_MARK
    DEFAULT_MARK = new_mark

def LoadFromFileExtension():
    for extension in FILE_EXTENSIONS:
        vim.command("au BufRead,BufNewFile *" + extension + "\= set ft=tl")
EOF




fun! Loadvimtl()
    " Transforma de una notación a la otra
    map ,1 :python tlConvertToOTL()<CR>
    map ,2 :python tlConvertToBOX()<CR>
    map ,3 :python tlConvertToSingle()<CR>

    imap ,1 <ESC>,1a
    imap ,2 <ESC>,2a
    imap ,3 <ESC>,3a

    " Crea o limpia una tarea. 
    " 'C' viene de Create y Clear.
    map ,c :python CreateTask()<CR>A
    imap ,c <ESC>,c

    " Agrega una tarea a la lista actual.
    " 'A' viene de append.
    map ,a :python CreateTaskIndent()<CR>A
    imap ,a <ESC>,a

    " Genera una subtarea para la tarea actual.
    " 'S' viene de SubTask.
    map  ,s :python CreateSubTask()<CR>A
    imap ,s <ESC>,s

    " Marca una tarea como realizada.
    " 'D' viene de Done.
    imap ,d <ESC>:python MarkDone()<CR>A
    map  ,d :python MarkDone()<CR>

    " Genera una subtarea para la tarea actual.
    " 'R' viene de Reject.
    map  ,r :python MarkCancel()<CR>A
    imap ,r <ESC>,r

    :python detectMarkStyle()

    set ft=tl
endf

endif
