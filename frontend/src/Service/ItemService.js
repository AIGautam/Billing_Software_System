import api from "./api";

export const addItem = async (item) => {
    return await api.post("/admin/items", item);
}

export const deleteItem = async (itemId) => {
    return await api.delete(`/admin/items/${itemId}`);
}

export const fetchItems = async () => {
    return await api.get("/items");
}
