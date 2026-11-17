// ESQUEMA DE LA BASE DE DATOS MongoDB DEL HOSPITAL DISTRIBUIDO

db = db.getSiblingDB("hospital");

db.createCollection("catalogo_estudios", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [ "clave", "nombre", "tipo", "precio", "activo"],
      properties: {
        clave: { bsonType: "string" },
        nombre: { bsonType: "string" },
        tipo: { bsonType: "string" , enum: ["laboratorio","imagen"] },
        precio: { bsonType: "decimal" , minimum: 0},
        activo: { bsonType: "bool" },
        parametros: {
          bsonType: "array",
          items: { 
            bsonType: "object",
            required: ["nombre"],
            properties: {
              nombre: { bsonType: "string" },
              unidad: { bsonType: "string" },
              rango_min: { bsonType: "number" },
              rango_max: { bsonType: "number" }
            }
          }
        }
      }
    }
  }
});

db.catalogo_estudios.createIndex({ clave: 1 }, { unique: true });

db.createCollection("expedientes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [ "paciente_id", "alergias", "consultas", "creado_en", "actualizado_en"],
      properties: {
        paciente_id: { bsonType: "int", minimum: 1 },
        alergias: { 
            bsonType: "array",
            items: { bsonType: "string" }
         },
        enfermedades_cronicas: { 
            bsonType: "array",
            items: { bsonType: "string"}
         },
        antecedentes: { bsonType: "object"},
        consultas: { 
            bsonType: "array",
            items: {
                bsonType: "object",
                required:["nota_id", "fecha", "medico_id"],
                properties: {
                    nota_id: { bsonType: "objectId"},
                    fecha: {bsonType: "date"},
                    medico_id: {bsonType: "int"},
                }
            },
        },
        creado_en: { bsonType: "date" },
        actualizado_en: { bsonType: "date" }
      }
    }
  }
});

db.expedientes.createIndex({ paciente_id: 1 }, { unique: true });


db.createCollection("notas_consulta", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [ "paciente_id", "cita_id", "medico_id", "especialidad", "fecha", "motivo", "diagnostico"],
      properties: {
        paciente_id: { bsonType: "int", minimum: 1 },
        cita_id: { bsonType: ["int","long"], minimum: 1 },
        medico_id: { bsonType: "int"},
        especialidad: { bsonType: "string" },
        fecha: { bsonType: "date"},
        motivo: { bsonType: "string" },
        diagnostico: { bsonType: "string" },
        signos_vitales: { 
            bsonType: "object",
            properties: {
                presion_sistolica: { bsonType: "number" },
                presion_diastolica: { bsonType: "number" },
                frecuencia_cardiaca: { bsonType: "number" },
                temperatura: { bsonType: "number" },
                peso: { bsonType: "number" }
            }
        },
        exploracion: {
            bsonType: "object",
        },
        plan: { bsonType: "string" },
        estudios_solicitados: {
            bsonType: "array",
            items: {
                bsonType: "string"
            }
        }
      }
    }
  }
});

db.notas_consulta.createIndex({ paciente_id: 1, fecha: -1 });
db.notas_consulta.createIndex({ cita_id: 1 });


db.createCollection("resultados_laboratorio", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: [ "paciente_id","nota_id", "clave_estudio", "estado", "solicitado_en"],
            properties: {
                paciente_id: { bsonType: "int", minimum: 1 },
                nota_id: { bsonType: "objectId" },
                clave_estudio: { bsonType: "string" },
                estado: { bsonType: "string", enum: ["solicitado", "en_proceso", "completado", "cancelado"] },
                solicitado_en: { bsonType: "date" },
                completado_en: { bsonType: "date" },
                resultados: {
                    bsonType: "array",
                    items: {
                        bsonType: "object",
                        required: ["parametro", "valor"],
                        properties:{
                            parametro: { bsonType: "string" },
                            valor: { bsonType: "number" },
                            unidad: { bsonType: "string" },
                            fuera_de_rango: { bsonType: "bool" }
                        }
                    }
                },
                informe: { bsonType: "string" },
            },
            anyOf: [
                {properties: {estado: {enum: ["solicitado", "en_proceso", "cancelado"]}}},
                {required: ["completado_en"]}
            ]
        }
    }
});


db.resultados_laboratorio.createIndex({ paciente_id: 1, solicitado_en: -1 });
db.resultados_laboratorio.createIndex({ nota_id: 1 });


db.createCollection("eventos", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["tipo", "paciente_id", "cita_id", "motor", "exito", "fecha"],
            properties: {
                tipo: { bsonType: "string", enum: ["cita_agendada", "check_in","nota_registrada", "estudio_solicitado", "receta_surtida", "cita_cerrada", "compensacion"] },
                paciente_id: { bsonType: "int", minimum: 1 },
                cita_id: { bsonType: ["int", "long"], minimum: 1 },
                motor: { bsonType: "string", enum: ["mysql", "postgresql", "mongodb"] },
                exito: { bsonType: "bool" },
                error: { bsonType: "string" },
                detalle: { bsonType: "object" },
                fecha: { bsonType: "date" }
            },
            anyOf: [
                {properties: {exito: {enum: [true]}}}, 
                {required: ["error"]}]
        }
    }
});


db.eventos.createIndex({ cita_id: 1, fecha: 1 });
db.eventos.createIndex({ paciente_id: 1, fecha: -1 });