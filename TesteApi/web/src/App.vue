<template>
  <div class="app">
    <h1>🔍 Busca de Operadoras de Saúde</h1>
    
    <div class="search-box">
      <input 
        v-model="termoBusca" 
        placeholder="Digite SP, saúde, administradora..."
        @keydown.enter="buscarOperadoras"
      />
      <button @click="buscarOperadoras">Buscar</button>
    </div>

    <div v-if="carregando" class="loading">Carregando...</div>
    
    <div v-if="erro" class="error">{{ erro }}</div>

    <div v-if="resultados.length > 0">
      <p class="total">Encontrados: {{ totalResultados }} resultados</p>
      
      <div v-for="(item, index) in resultados" :key="index" class="card">
        <h3>{{ item.Razao_Social }}</h3>
        <p v-if="item.Nome_Fantasia"><em>{{ item.Nome_Fantasia }}</em></p>
        
        <div class="details">
          <p><strong>CNPJ:</strong> {{ item.CNPJ }}</p>
          <p><strong>ANS:</strong> {{ item.Registro_ANS }}</p>
          <p><strong>Cidade:</strong> {{ item.Cidade }}/{{ item.UF }}</p>
          <p v-if="item.Telefone"><strong>Tel:</strong> {{ item.Telefone }}</p>
        </div>
      </div>
    </div>

    <div v-else-if="mostrarMensagemVazio" class="empty">
      Nenhum resultado encontrado para "{{ termoBusca }}"
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import axios from 'axios'

const API_URL = 'http://localhost:5000'

const termoBusca = ref('')
const resultados = ref([])
const carregando = ref(false)
const erro = ref('')
const totalResultados = ref(0)
const mostrarMensagemVazio = ref(false)

const buscarOperadoras = async () => {
  if (termoBusca.value.length < 2) {
    erro.value = 'Digite pelo menos 2 caracteres'
    mostrarMensagemVazio.value = false
    return
  }

  carregando.value = true
  erro.value = ''
  mostrarMensagemVazio.value = false
  
  try {
    const response = await axios.get(`${API_URL}/buscar`, {
      params: { termo: termoBusca.value }
    })
    
    resultados.value = response.data.resultados
    totalResultados.value = response.data.total
    mostrarMensagemVazio.value = resultados.value.length === 0
  } catch (err) {
    erro.value = err.response?.data?.erro || 'Erro na busca'
    mostrarMensagemVazio.value = false
  } finally {
    carregando.value = false
  }
}
</script>

<style>
.app {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  font-family: Arial, sans-serif;
}

h1 {
  color: #2c3e50;
  text-align: center;
  margin-bottom: 20px;
}

.search-box {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

input {
  flex: 1;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

button {
  padding: 10px 20px;
  background: #42b983;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button:hover {
  background: #369f6b;
}

.card {
  background: white;
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 15px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  color: #333;
}

.details {
  margin-top: 10px;
  font-size: 14px;
}

.details p {
  margin: 5px 0;
}

.loading {
  text-align: center;
  padding: 20px;
  color: #42b983;
}

.error {
  color: #ff5252;
  padding: 10px;
  background: #fff0f0;
  border-radius: 4px;
  margin-bottom: 20px;
}

.total {
  color: #666;
  margin-bottom: 15px;
}

.empty {
  text-align: center;
  color: #666;
  padding: 20px;
}
</style>