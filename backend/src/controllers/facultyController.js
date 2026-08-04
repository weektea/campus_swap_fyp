import Faculty, { seedInitialFaculties } from '../models/Faculty.js';

// Public GET for students/users dropdown
export const getPublicFaculties = async (req, res) => {
    try {
        await seedInitialFaculties();
        const faculties = await Faculty.findAll({
            where: { is_active: true },
            order: [['code', 'ASC']]
        });
        res.json(faculties);
    } catch (error) {
        console.error('Error fetching public faculties:', error);
        res.status(500).json({ error: 'Failed to fetch faculties' });
    }
};

// Admin CRUD Controller Functions
export const getAllFaculties = async (req, res) => {
    try {
        await seedInitialFaculties();
        const faculties = await Faculty.findAll({
            order: [['code', 'ASC']]
        });
        res.json(faculties);
    } catch (error) {
        console.error('Error fetching admin faculties:', error);
        res.status(500).json({ error: 'Failed to fetch faculties' });
    }
};

export const createFaculty = async (req, res) => {
    try {
        const { code, name, is_active } = req.body;
        if (!code || !name) {
            return res.status(400).json({ error: 'Faculty short code and name are required' });
        }

        const existing = await Faculty.findOne({ where: { code: code.trim().toUpperCase() } });
        if (existing) {
            return res.status(400).json({ error: `Faculty code '${code.toUpperCase()}' already exists` });
        }

        const faculty = await Faculty.create({
            code: code.trim().toUpperCase(),
            name: name.trim(),
            is_active: is_active !== undefined ? is_active : true,
        });

        res.status(201).json(faculty);
    } catch (error) {
        console.error('Error creating faculty:', error);
        res.status(500).json({ error: 'Failed to create faculty' });
    }
};

export const updateFaculty = async (req, res) => {
    try {
        const { id } = req.params;
        const { code, name, is_active } = req.body;

        const faculty = await Faculty.findByPk(id);
        if (!faculty) {
            return res.status(404).json({ error: 'Faculty not found' });
        }

        if (code !== undefined) faculty.code = code.trim().toUpperCase();
        if (name !== undefined) faculty.name = name.trim();
        if (is_active !== undefined) faculty.is_active = is_active;

        await faculty.save();
        res.json(faculty);
    } catch (error) {
        console.error('Error updating faculty:', error);
        res.status(500).json({ error: 'Failed to update faculty' });
    }
};

export const deleteFaculty = async (req, res) => {
    try {
        const { id } = req.params;
        const faculty = await Faculty.findByPk(id);
        if (!faculty) {
            return res.status(404).json({ error: 'Faculty not found' });
        }

        await faculty.destroy();
        res.json({ message: 'Faculty deleted successfully' });
    } catch (error) {
        console.error('Error deleting faculty:', error);
        res.status(500).json({ error: 'Failed to delete faculty' });
    }
};
