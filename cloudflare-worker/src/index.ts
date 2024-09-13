export interface Env {
	DB: D1Database;
  }
  
  export default {
	async fetch(request: Request, env: Env): Promise<Response> {
	  return handleRequest(request, env);
	}
  };
  
  async function handleRequest(request: Request, env: Env): Promise<Response> {
	const url = new URL(request.url);
	const path = url.pathname;
  
	if (path === '/test-db') {
	  return handleTestDB(env);
	}
  
	if (path === '/clothing') {
	  if (request.method === 'POST') {
		return handleCreateClothing(request, env);
	  } else if (request.method === 'GET') {
		return handleGetAllClothing(env);
	  }
	} else if (path.startsWith('/clothing/')) {
	  const id = path.split('/')[2];
	  if (request.method === 'GET') {
		return handleGetClothing(id, env);
	  } else if (request.method === 'PUT') {
		return handleUpdateClothing(id, request, env);
	  } else if (request.method === 'DELETE') {
		return handleDeleteClothing(id, env);
	  }
	}
  
	return new Response('Not Found', { status: 404 });
  }
  
  async function handleTestDB(env: Env): Promise<Response> {
	try {
	  const { results } = await env.DB.prepare('SELECT 1 AS test').all();
	  return new Response(JSON.stringify(results), {
		status: 200,
		headers: { 'Content-Type': 'application/json' }
	  });
	} catch (error: any) {
	  return new Response(JSON.stringify({ error: 'Database connection failed', details: error.message }), {
		status: 500,
		headers: { 'Content-Type': 'application/json' }
	  });
	}
  }
  
  async function handleCreateClothing(request: Request, env: Env): Promise<Response> {
	try {
	  const requestJson: any = await request.json();
	  const id = crypto.randomUUID();
  
	  const stmt = env.DB.prepare(
		'INSERT INTO clothing_items (id, type, color, image_id) VALUES (?, ?, ?, ?)'
	  );
	  await stmt.bind(id, requestJson.type, requestJson.color, requestJson.imageId).run();
  
	  return new Response(JSON.stringify({ id, type: requestJson.type, color: requestJson.color, imageId: requestJson.imageId }), {
		status: 201,
		headers: { 'Content-Type': 'application/json' }
	  });
	} catch (error: any) {
	  return new Response(JSON.stringify({ error: 'Invalid request', details: error.message }), {
		status: 400,
		headers: { 'Content-Type': 'application/json' }
	  });
	}
  }
  
  async function handleGetAllClothing(env: Env): Promise<Response> {
	const { results } = await env.DB.prepare('SELECT * FROM clothing_items').all();
	return new Response(JSON.stringify(results), {
	  headers: { 'Content-Type': 'application/json' }
	});
  }
  
  async function handleGetClothing(id: string, env: Env): Promise<Response> {
	const stmt = env.DB.prepare('SELECT * FROM clothing_items WHERE id = ?');
	const { results } = await stmt.bind(id).all();
  
	if (results.length === 0) {
	  return new Response('Not Found', { status: 404 });
	}
  
	return new Response(JSON.stringify(results[0]), {
	  headers: { 'Content-Type': 'application/json' }
	});
  }
  
  async function handleUpdateClothing(id: string, request: Request, env: Env): Promise<Response> {
	try {
	    const requestJson: any = await request.json();
	  const stmt = env.DB.prepare(
		'UPDATE clothing_items SET type = ?, color = ?, image_id = ? WHERE id = ?'
	  );
	  const result: any = await stmt.bind(id, requestJson.type, requestJson.color, requestJson.imageId).run();
  
	  if (result.changes === 0) {
		return new Response('Not Found', { status: 404 });
	  }
  
	  return new Response(JSON.stringify({ id, type: requestJson.type, color: requestJson.color, imageId: requestJson.imageId }), {
		headers: { 'Content-Type': 'application/json' }
	  });
	} catch (error: any) {
	  return new Response(JSON.stringify({ error: 'Invalid request', details: error.message }), {
		status: 400,
		headers: { 'Content-Type': 'application/json' }
	  });
	}
  }
  
  async function handleDeleteClothing(id: string, env: Env): Promise<Response> {
	const stmt = env.DB.prepare('DELETE FROM clothing_items WHERE id = ?');
	const result: any = await stmt.bind(id).run();
  
	if (result.changes === 0) {
	  return new Response('Not Found', { status: 404 });
	}
  
	return new Response(null, { status: 204 });
  }