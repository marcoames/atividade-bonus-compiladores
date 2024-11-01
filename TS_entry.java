import java.util.ArrayList;

public class TS_entry {
    private String id;
    private ClasseID classe;  
    private TS_entry tipo;
    private String escopo;

    public TS_entry(String umId, TS_entry umTipo, ClasseID umaClasse, String umEscopo) {
        id = umId;
        tipo = umTipo; // This should reference the type (e.g., int, struct)
        classe = umaClasse;
        escopo = umEscopo;
    }

    public String getId() {
        return id; 
    }

    public TS_entry getTipo() {
        return tipo; 
    }

    public ClasseID getClasse() {
        return classe;
    }

    public String getEscopo() {
        return escopo;
    }

    public String toString() {
        StringBuilder aux = new StringBuilder();
        
        aux.append("Id: ").append(String.format("%-10s", id));
        aux.append("\tClasse: ").append(classe);
        aux.append("\tTipo: ").append(tipo2str(this.tipo));
        aux.append("\tEscopo: ").append(escopo);

        return aux.toString();
    }

    public String getTipoStr() {
        return tipo2str(this); 
    }

    public String tipo2str(TS_entry tipo) {
        if (tipo == null)  return "null"; 
        else if (tipo==Parser.Tp_INT)    return "int"; 
        else if (tipo==Parser.Tp_BOOL)   return "boolean"; 
        else if (tipo==Parser.Tp_DOUBLE)  return "double";
        else if (tipo==Parser.Tp_FLOAT)  return "float";
        else if (tipo==Parser.Tp_STRUCT)  return "struct";
        else if (tipo==Parser.Tp_FLOAT)  return "float";
        else if (tipo==Parser.Tp_STRING)  return "string";
        else if (tipo==Parser.Tp_ERRO)  return  "_erro_";
        else return tipo2str(tipo.getTipo());
    }
  
}
